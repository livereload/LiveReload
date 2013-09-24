
#import "Glitter.h"
#import "GlitterFeed.h"
#import "GlitterVersionUtilities.h"
#import "GlitterArchiveUtilities.h"


#define GlitterChannelNamePreferenceKey @"GlitterDefaultChannelName"

#define GlitterStateFileNameKey @"file"
#define GlitterStateVersionKey @"version"
#define GlitterStateVersionDisplayNameKey @"versionDisplayName"
#define GlitterStateStatusKey @"status"
#define GlitterStateStatusValueInstall @"install"



@interface Glitter () <NSURLConnectionDelegate>

@end



@implementation Glitter {
    NSBundle *_bundle;
    NSString *_preferenceKeyPrefix;
    NSURL *_feedURL;
    NSString *_defaultChannelName;
    NSString *_currentVersion;
    NSString *_currentVersionDisplayName;

    NSURL *_updateFolderURL;
    NSURL *_extractionFolderURL;
    NSURL *_feedFileURL;
    NSURL *_statusFileURL;

    BOOL _checking;
    BOOL _checkIsUserInitiated;

    NSArray *_availableVersions;
    GlitterErrorCode _lastCheckError;
    GlitterVersion *_nextVersion;

    GlitterVersion *_downloadingVersion;
    NSURL *_downloadLocalURL;
    NSURLConnection *_downloadingConnection;
    NSMutableData *_downloadingData;

    GlitterVersion *_readyToInstallVersion;
    NSURL *_readyToInstallLocalURL;
}

- (id)initWithMainBundle {
    self = [super init];
    if (self) {
        _bundle = [NSBundle mainBundle];
        _preferenceKeyPrefix = [NSString stringWithFormat:@"Glitter.%@", _bundle.bundleIdentifier];
        _currentVersion = [[_bundle infoDictionary] objectForKey:@"CFBundleVersion"];
        _currentVersionDisplayName = [[_bundle infoDictionary] objectForKey:@"CFBundleShortVersionString"] ?: _currentVersion;

        NSString *feedURLString = [[_bundle infoDictionary] objectForKey:GlitterFeedURLKey];
        NSAssert(!!feedURLString, @"Glitter configuration error: " GlitterFeedURLKey @" must be specified in bundle's Info.plist");
        _feedURL = [NSURL URLWithString:feedURLString];

        _defaultChannelName = [[_bundle infoDictionary] objectForKey:GlitterDefaultChannelNameKey];
        if (!_defaultChannelName)
            _defaultChannelName = GlitterChannelNameStable;

        NSString *appSupportSubfolder = [[_bundle infoDictionary] objectForKey:GlitterApplicationSupportSubfolderKey];
        NSAssert(!!appSupportSubfolder, @"Glitter configuration error: " GlitterApplicationSupportSubfolderKey @" must be specified in bundle's Info.plist");

        NSFileManager *fm = [NSFileManager defaultManager];

        NSError * __autoreleasing error = nil;
        _updateFolderURL = [[fm URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error] URLByAppendingPathComponent:appSupportSubfolder];
        NSAssert(!!_updateFolderURL, @"Glitter initialization error - cannot obtain Application Support folder: %@", error.localizedDescription);

        [fm createDirectoryAtURL:_updateFolderURL withIntermediateDirectories:YES attributes:nil error:NULL];

        _feedFileURL = [_updateFolderURL URLByAppendingPathComponent:@"feed.json"];
        _statusFileURL = [_updateFolderURL URLByAppendingPathComponent:@"status.json"];
        _extractionFolderURL = [_updateFolderURL URLByAppendingPathComponent:@"extracted"];

        _availableVersions = [NSArray array];
    }
    return self;
}

- (NSString *)channelName {
    return [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@.%@", _preferenceKeyPrefix, GlitterChannelNamePreferenceKey]] ?: _defaultChannelName;
}

- (void)setChannelName:(NSString *)channelName {
    NSString *key = [NSString stringWithFormat:@"%@.%@", _preferenceKeyPrefix, GlitterChannelNamePreferenceKey];
    if (channelName.length == 0)
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    else
        [[NSUserDefaults standardUserDefaults] setObject:channelName forKey:key];
}

- (void)checkForUpdatesWithOptions:(GlitterCheckOptions)options {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (options & GlitterCheckOptionUserInitiated)
            _checkIsUserInitiated = YES;
        if (_checking) return;

        [self willChangeValueForKey:@"checking"];
        _checking = YES;
        [self didChangeValueForKey:@"checking"];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSError *error = nil;
            NSArray *availableVersions = nil;

            NSData *feedData = [NSData dataWithContentsOfURL:_feedURL options:0 error:&error];
            if (!feedData)
                error = [NSError errorWithDomain:@"Glitter" code:GlitterErrorCodeCheckFailedConnection userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"failed to download feed: %@", error.localizedDescription], NSUnderlyingErrorKey: error}];
            else {
                BOOL ok = [feedData writeToURL:_feedFileURL options:NSDataWritingAtomic error:&error];
                if (!ok) {
                    NSLog(@"[Glitter] Update check (feed URL %@) - failed to save feed JSON into %@: %@", _feedURL, _feedFileURL, error.localizedDescription);
                }

                availableVersions = GlitterParseFeedData(feedData, &error);
            }

            if (!availableVersions) {
                NSLog(@"[Glitter] Update check failed (feed URL %@) - %@", _feedURL, error.localizedDescription);
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                if (availableVersions) {
                    _lastCheckError = GlitterErrorCodeNone;
                    _availableVersions = availableVersions;
                    [self updateAvailability];
                } else {
                    if ([error.domain isEqualToString:@"Glitter"])
                        _lastCheckError = (GlitterErrorCode)error.code;
                    else
                        _lastCheckError = GlitterErrorCodeCheckFailedConnection;  // safer choice
                }

                BOOL displayMessage = _checkIsUserInitiated;

                [self willChangeValueForKey:@"checking"];
                _checking = NO;
                [self didChangeValueForKey:@"checking"];
                _checkIsUserInitiated = NO;

                if (displayMessage) {
                    // give UI a bit of time to update
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
                        [self _displayLastUpdateCheckResult];
                    });
                }
            });
        });
    });
}

- (void)updateAvailability {
    NSString *currentVersion = _currentVersion;
    NSString *channelName = self.channelName;
    
    NSLog(@"currentVersion = %@, availableVersions = %@", currentVersion, _availableVersions);
    GlitterVersion *nextVersion = nil;
    for (GlitterVersion *version in _availableVersions) {
        NSString *whyNot = nil;
        if (![version.channelNames containsObject:channelName]) {
            whyNot = [NSString stringWithFormat:@"current channel %@ does not match version's channels %@", channelName, [version.channelNames componentsJoinedByString:@"+"]];
            goto not_matched;
        }
        if (GlitterCompareVersions(currentVersion, version.version) != NSOrderedAscending) {
            whyNot = [NSString stringWithFormat:@"current version %@ is not less than version '%@'", currentVersion, version.version];
            goto not_matched;
        }
        if (version.compatibleVersionRange.length > 0 && !GlitterMatchVersionRange(version.compatibleVersionRange, currentVersion)) {
            whyNot = [NSString stringWithFormat:@"current version %@ does not match version's compatible version range '%@'", currentVersion, version.compatibleVersionRange];
            goto not_matched;
        }

        nextVersion = version;
        break;

    not_matched:
        NSLog(@"Version %@ does not match: %@", version, whyNot);
    }

    _nextVersion = nextVersion;

    [self downloadUpdate];
}

- (void)_displayLastUpdateCheckResult {
//    if (_lastCheckError == GlitterErrorCodeNone) {
//        if (_nextVersion) {
//            [[NSAlert alertWithMessageText:@"Update found" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Found version %@ (you have version %@).", _nextVersion.versionDisplayName, _currentVersionDisplayName]runModal];
//        } else {
//            [[NSAlert alertWithMessageText:@"No updates found" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"You are running the latest version."]runModal];
//        }
//    } else {
//        [[NSAlert alertWithMessageText:@"Update check failed" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"There was a problem checking for update."]runModal];
//    }
}


#pragma mark - Downloading

- (void)_cancelDownload {
    if (_downloadingConnection) {
        [_downloadingConnection cancel];
        _downloadingConnection = nil;
    }
}

- (void)downloadUpdate {
    if (_nextVersion == nil) {
        if (_downloadingVersion != nil) {
            [self _cancelDownload];
        }
        return;
    }
    if ([_readyToInstallVersion.identifier isEqualToString:_nextVersion.identifier]) {
        return; // nothing to do
    }
    if ([_downloadingVersion.identifier isEqualToString:_nextVersion.identifier]) {
        return; // nothing to do
    }

    [self _cancelDownload];

    _downloadingVersion = _nextVersion;
    _downloadingData = [[NSMutableData alloc] initWithCapacity:(NSUInteger)_downloadingVersion.source.size];
    _downloadLocalURL = [_updateFolderURL URLByAppendingPathComponent:[_downloadingVersion.source.url lastPathComponent]];

    NSURLRequest *request = [NSURLRequest requestWithURL:_downloadingVersion.source.url];
    _downloadingConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];

    NSLog(@"[Glitter] Downloading version %@ from %@", _downloadingVersion.version, _downloadingVersion.source.url);
}

- (void)_finishDownload {
    if (_downloadingData) {
        // TODO verify length of data and SHA1 sum

        NSError * __autoreleasing error = nil;
        BOOL ok = [_downloadingData writeToURL:_downloadLocalURL options:NSDataWritingAtomic error:&error];
        if (!ok) {
            NSLog(@"[Glitter] Update download failed (version %@ at %@) - cannot save binary file %@: %@", _downloadingVersion.version, _downloadingVersion.source.url, _downloadLocalURL.path, error.localizedDescription);
        } else {
            NSDictionary *statusData = @{
                GlitterStateFileNameKey: [_downloadLocalURL lastPathComponent],
                GlitterStateVersionKey: _downloadingVersion.version,
                GlitterStateVersionDisplayNameKey: _downloadingVersion.versionDisplayName,
                GlitterStateStatusKey: GlitterStateStatusValueInstall,
            };
            NSData *data = [NSJSONSerialization dataWithJSONObject:statusData options:NSJSONWritingPrettyPrinted error:NULL];
            ok = [data writeToURL:_statusFileURL options:NSDataWritingAtomic error:&error];
            if (!ok) {
                NSLog(@"[Glitter] Update download failed (version %@ at %@) - cannot save status file %@: %@", _downloadingVersion.version, _downloadingVersion.source.url, _statusFileURL.path, error.localizedDescription);
            } else {
                [[NSFileManager defaultManager] removeItemAtURL:_extractionFolderURL error:NULL];
                [[NSFileManager defaultManager] createDirectoryAtURL:_extractionFolderURL withIntermediateDirectories:YES attributes:nil error:NULL];

                NSLog(@"[Glitter] Unzipping %@", [_downloadLocalURL lastPathComponent]);

                GlitterUnzip(_downloadLocalURL, _extractionFolderURL, ^(NSError *unzipError) {
                    if (unzipError) {
                        NSLog(@"[Glitter] Update extraction failed (version %@ at %@) - cannot unzip %@: %@", _downloadingVersion.version, _downloadingVersion.source.url, _downloadLocalURL.path, unzipError.localizedDescription);
                    } else {
                        NSError * __autoreleasing error = nil;
                        NSArray *items = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:_extractionFolderURL includingPropertiesForKeys:@[] options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
                        if (!items) {
                            NSLog(@"[Glitter] Update extraction failed (version %@ at %@) - cannot enumerate %@: %@", _downloadingVersion.version, _downloadingVersion.source.url, _extractionFolderURL.path, error.localizedDescription);
                        } else {
                            if (items.count != 1) {
                                NSLog(@"[Glitter] Update extraction failed (version %@ at %@) - multiple items found in %@: %@", _downloadingVersion.version, _downloadingVersion.source.url, _extractionFolderURL.path, items);
                            } else {
                                _readyToInstallVersion = _downloadingVersion;
                                _readyToInstallLocalURL = items[0]; //[_updateFolderURL URLByAppendingPathComponent:statusData[GlitterStateFileNameKey]];
                                NSLog(@"[Glitter] Item to install: %@", _readyToInstallLocalURL.path);
                                NSLog(@"[Glitter] Version %@ is ready to install.", _readyToInstallVersion.version);

                                [self installUpdate];
                            }
                        }
                    }
                });
////                ok = [SSZipArchive unzipFileAtPath:_downloadLocalURL.path toDestination:_extractionFolderURL.path overwrite:NO password:nil error:&error delegate:nil];
//                if (!ok) {
////                    NSLog(@"[Glitter] Update extraction failed (version %@ at %@) - cannot unzip %@: %@", _downloadingVersion.version, _downloadingVersion.source.url, _downloadLocalURL.path, error.localizedDescription);
//                    NSLog(@"[Glitter] Update extraction failed (version %@ at %@) - cannot unzip %@", _downloadingVersion.version, _downloadingVersion.source.url, _downloadLocalURL.path);
//                } else {
//                }
            }
        }
    }

    _downloadingVersion = nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSInteger code = [(NSHTTPURLResponse *)response statusCode];
    if (code != 200) {
        [connection cancel];
        NSLog(@"[Glitter] Update download failed (version %@ at %@): response code %d", _downloadingVersion.version, _downloadingVersion.source.url, (int)code);
        _downloadingData = nil;
        [self _finishDownload];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_downloadingData appendData:data];
    double percentage = 100 * (_downloadingData.length / (double)_downloadingVersion.source.size);
    NSLog(@"[Glitter] Downloading version %@ from %@: %.0lf%% done", _downloadingVersion.version, _downloadingVersion.source.url, percentage);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"[Glitter] Update download failed (version %@ at %@): %@", _downloadingVersion.version, _downloadingVersion.source.url, error.localizedDescription);
    _downloadingData = nil;
    [self _finishDownload];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self _finishDownload];
}


#pragma mark - Restart

- (void)installUpdate {
    xpc_connection_t connection = xpc_connection_create("com.tarantsov.GlitterInstallationService", dispatch_get_main_queue());
    xpc_connection_set_event_handler(connection, ^(xpc_object_t event) {
        xpc_type_t type = xpc_get_type(event);
        if (type == XPC_TYPE_ERROR) {
            if (event == XPC_ERROR_CONNECTION_INVALID) {
                NSLog(@"XPC: XPC_ERROR_CONNECTION_INVALID");
            } else if (event == XPC_ERROR_CONNECTION_INTERRUPTED) {
                NSLog(@"XPC: XPC_ERROR_CONNECTION_INTERRUPTED");
            }
        } else {
            assert(type == XPC_TYPE_DICTIONARY);
            NSLog(@"XPC: incoming message");
        }
    });
    xpc_connection_resume(connection);

    [[NSAlert alertWithMessageText:@"Ready to install" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Click OK to install version %@ (you have version %@).", _nextVersion.versionDisplayName, _currentVersionDisplayName]runModal];

    xpc_object_t message = xpc_dictionary_create(NULL, NULL, 0);
    xpc_dictionary_set_string(message, "bundlePath", [[_bundle bundlePath] UTF8String]);
    xpc_dictionary_set_string(message, "updatePath", [_readyToInstallLocalURL.path UTF8String]);
    xpc_connection_send_message(connection, message);
    xpc_connection_send_barrier(connection, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
//            xpc_connection_get_context(connection); // dummy call to create a reference
            exit(0);
        });
    });
}

@end
