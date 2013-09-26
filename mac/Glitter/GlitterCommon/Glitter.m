
#import "Glitter.h"
#import "GlitterFeed.h"
#import "GlitterVersionUtilities.h"
#import "GlitterArchiveUtilities.h"


#define GlitterChannelNamePreferenceKey @"DefaultChannelName"
#define GlitterAutomaticCheckingEnabledPreferenceKey @"AutomaticCheckingEnabled"

#define GlitterDebugModePreferenceKey @"Debug"

#define GlitterStateFileNameKey @"file"
#define GlitterStateVersionKey @"version"
#define GlitterStateVersionDisplayNameKey @"versionDisplayName"
#define GlitterStateVersionIdentifierKey @"id"



NSString *const GlitterStatusDidChangeNotification = @"GlitterStatusDidChangeNotification";
NSString *const GlitterUserInitiatedUpdateCheckDidFinishNotification = @"GlitterUserInitiatedUpdateCheckDidFinishNotification";



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

    BOOL _readyToInstall;
    NSString *_readyToInstallVersion;
    NSString *_readyToInstallVersionDisplayName;
    NSString *_readyToInstallVersionIdentifier;
    NSURL *_readyToInstallLocalURL;

    BOOL _notificationScheduled;

    NSTimeInterval _automaticCheckInterval;
    NSTimeInterval _automaticCheckRetryInterval;
    NSTimeInterval _lastCheckTime;
    dispatch_source_t _automaticCheckTimer;

    BOOL _debug;
}

- (id)initWithMainBundle {
    self = [super init];
    if (self) {
        _bundle = [NSBundle mainBundle];

        if (_bundle == [NSBundle mainBundle]) {
            _preferenceKeyPrefix = @"Glitter";
        } else {
            _preferenceKeyPrefix = [NSString stringWithFormat:@"Glitter.%@.", _bundle.bundleIdentifier];
        }
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
        _updateFolderURL = [[fm URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:&error] URLByAppendingPathComponent:appSupportSubfolder];
        NSAssert(!!_updateFolderURL, @"Glitter initialization error - cannot obtain Application Support folder: %@", error.localizedDescription);

        _statusFileURL = [_updateFolderURL URLByAppendingPathComponent:@"status.json"];
        _extractionFolderURL = [_updateFolderURL URLByAppendingPathComponent:@"extracted"];

        _availableVersions = [NSArray array];

        [[NSUserDefaults standardUserDefaults] registerDefaults:@{
            self.automaticCheckingEnabledPreferenceKey: @YES,
        }];

        [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:self.automaticCheckingEnabledPreferenceKey options:0 context:0];

        [self _updateDebugMode];
        [self _loadReadyToInstallVersionIfAny];
        [self installUpdate];
        [self _updateAutomaticCheckingTimer];
    }
    return self;
}

- (void)dealloc {
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:self.automaticCheckingEnabledPreferenceKey];
}


#pragma mark - Preference keys

- (NSString *)channelNamePreferenceKey {
    return [NSString stringWithFormat:@"%@%@", _preferenceKeyPrefix, GlitterChannelNamePreferenceKey];
}

- (NSString *)automaticCheckingEnabledPreferenceKey {
    return [NSString stringWithFormat:@"%@%@", _preferenceKeyPrefix, GlitterAutomaticCheckingEnabledPreferenceKey];
}

- (NSString *)debugModePreferenceKey {
    return [NSString stringWithFormat:@"%@%@", _preferenceKeyPrefix, GlitterDebugModePreferenceKey];
}


#pragma mark - Debug mode

- (void)_updateDebugMode {
    _debug = [[NSUserDefaults standardUserDefaults] boolForKey:self.debugModePreferenceKey];
    if (_debug) {
        _automaticCheckInterval = 30;            // 30 sec
        _automaticCheckRetryInterval = 5;        // 5 sec
    } else {
        _automaticCheckInterval = 60 * 60 * 24;  // 1 day
        _automaticCheckRetryInterval = 60 * 60;  // 1 hour
    }
}


#pragma mark - Channels

- (NSString *)channelName {
    return [[NSUserDefaults standardUserDefaults] objectForKey:self.channelNamePreferenceKey] ?: _defaultChannelName;
}

- (BOOL)isChannelNameSet {
    return !![[NSUserDefaults standardUserDefaults] objectForKey:self.channelNamePreferenceKey];
}

- (void)setChannelNameSet:(BOOL)channelNameSet {
    if (channelNameSet) {
        if (![[NSUserDefaults standardUserDefaults] objectForKey:self.channelNamePreferenceKey]) {
            [[NSUserDefaults standardUserDefaults] setObject:_defaultChannelName forKey:self.channelNamePreferenceKey];
        }
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.channelNamePreferenceKey];
    }
}

- (void)setChannelName:(NSString *)channelName {
    if (channelName.length == 0)
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:self.channelNamePreferenceKey];
    else
        [[NSUserDefaults standardUserDefaults] setObject:channelName forKey:self.channelNamePreferenceKey];
}


#pragma mark - Automatic checking

- (BOOL)isAutomaticCheckingEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:self.automaticCheckingEnabledPreferenceKey];
}

- (void)setAutomaticCheckingEnabled:(BOOL)automaticCheckingEnabled {
    [[NSUserDefaults standardUserDefaults] setBool:automaticCheckingEnabled forKey:self.automaticCheckingEnabledPreferenceKey];
//    [self _updateAutomaticCheckingTimer];
}

- (void)_updateAutomaticCheckingTimer {
    BOOL enabled = self.automaticCheckingEnabled;
    if (enabled) {
        NSTimeInterval nextTime = _lastCheckTime + (_lastCheckError == GlitterErrorCodeNone ? _automaticCheckInterval : _automaticCheckRetryInterval);
        NSTimeInterval untilNext = nextTime - [NSDate timeIntervalSinceReferenceDate];

        if (untilNext <= 0.1) {
            // time to check is right now; don't schedule a timer
            [self checkForUpdatesWithOptions:0];
            return;
        }

        if (!_automaticCheckTimer) {
            _automaticCheckTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
            dispatch_source_set_event_handler(_automaticCheckTimer, ^{
                [self checkForUpdatesWithOptions:0];
            });
            dispatch_resume(_automaticCheckTimer);
        }

        NSLog(@"Glitter: next automatic check in %.0lf s", untilNext);

        // this will reschedule the timer if it has been already set
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, untilNext * NSEC_PER_SEC);
        dispatch_source_set_timer(_automaticCheckTimer, time, DISPATCH_TIME_FOREVER, _automaticCheckInterval * NSEC_PER_SEC / 20);
    } else if (_automaticCheckTimer) {
        dispatch_source_cancel(_automaticCheckTimer);
        _automaticCheckTimer = nil;
    }
}


#pragma mark - Checking

- (void)checkForUpdatesWithOptions:(GlitterCheckOptions)options {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ((options & GlitterCheckOptionUserInitiated) && !_checkIsUserInitiated) {
            _checkIsUserInitiated = YES;
            [self statusDidChange];
        }
        if (_checking) return;

        _checking = YES;
        [self statusDidChange];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSError *error = nil;
            NSArray *availableVersions = nil;

            NSData *feedData = [NSData dataWithContentsOfURL:_feedURL options:0 error:&error];
            if (!feedData)
                error = [NSError errorWithDomain:@"Glitter" code:GlitterErrorCodeCheckFailedConnection userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"failed to download feed: %@", error.localizedDescription], NSUnderlyingErrorKey: error}];
            else {
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

                BOOL userInitiated = _checkIsUserInitiated;

                _checking = NO;
                _checkIsUserInitiated = NO;
                _lastCheckTime = [NSDate timeIntervalSinceReferenceDate];
                [self statusDidChange];

                [self _updateAutomaticCheckingTimer];

                if (userInitiated) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:GlitterUserInitiatedUpdateCheckDidFinishNotification object:self];
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


#pragma mark - Downloading

- (BOOL)isDownloading {
    return !!_downloadingVersion;
}

- (NSString *)downloadingVersionDisplayName {
    return _downloadingVersion.versionDisplayName;
}

- (void)_cleanupDownload {
    _downloadingVersion = nil;
    _downloadStep = GlitterDownloadStepNone;
    _downloadingConnection = nil;
    _downloadLocalURL = nil;
    [self _deleteUnnecessaryState];
    [self statusDidChange];
}

- (void)_cancelDownload {
    if (_downloadingConnection) {
        [_downloadingConnection cancel];
        _downloadingConnection = nil;
    }
    [self _cleanupDownload];
}

- (void)downloadUpdate {
    if (_nextVersion == nil) {
        if (_downloadingVersion != nil) {
            [self _cancelDownload];
        }
        return;
    }
    if (_readyToInstall && [_readyToInstallVersionIdentifier isEqualToString:_nextVersion.identifier]) {
        return; // nothing to do
    }
    if ([_downloadingVersion.identifier isEqualToString:_nextVersion.identifier]) {
        return; // nothing to do
    }

    [self _cancelDownload];

    _downloadingVersion = _nextVersion;
    _downloadingData = [[NSMutableData alloc] initWithCapacity:(NSUInteger)_downloadingVersion.source.size];
    _downloadLocalURL = [_updateFolderURL URLByAppendingPathComponent:[_downloadingVersion.source.url lastPathComponent]];
    _downloadProgress = 0.0;
    _downloadStep = GlitterDownloadStepDownload;

    NSURLRequest *request = [NSURLRequest requestWithURL:_downloadingVersion.source.url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0];
    _downloadingConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];

    NSLog(@"[Glitter] Downloading version %@ from %@", _downloadingVersion.version, _downloadingVersion.source.url);
    [self statusDidChange];
}

- (void)_finishDownload {
    if (!_downloadingData) {
        [self _cleanupDownload];
        return;
    }

    // TODO verify length of data and SHA1 sum

    NSError * __autoreleasing error = nil;
    [[NSFileManager defaultManager] createDirectoryAtURL:[_downloadLocalURL URLByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
    BOOL ok = [_downloadingData writeToURL:_downloadLocalURL options:NSDataWritingAtomic error:&error];
    if (!ok) {
        NSLog(@"[Glitter] Update download failed (version %@ at %@) - cannot save binary file %@: %@", _downloadingVersion.version, _downloadingVersion.source.url, _downloadLocalURL.path, error.localizedDescription);
        [self _cleanupDownload];
        return;
    }

    [[NSFileManager defaultManager] removeItemAtURL:_extractionFolderURL error:NULL];
    [[NSFileManager defaultManager] createDirectoryAtURL:_extractionFolderURL withIntermediateDirectories:YES attributes:nil error:NULL];

    NSLog(@"[Glitter] Unzipping %@", [_downloadLocalURL lastPathComponent]);

    _downloadStep = GlitterDownloadStepUnpack;
    [self statusDidChange];

    GlitterUnzip(_downloadLocalURL, _extractionFolderURL, ^(NSError *unzipError) {
        if (unzipError) {
            NSLog(@"[Glitter] Update extraction failed (version %@ at %@) - cannot unzip %@: %@", _downloadingVersion.version, _downloadingVersion.source.url, _downloadLocalURL.path, unzipError.localizedDescription);
            [self _cleanupDownload];
            return;
        }

        NSError * __autoreleasing error = nil;
        NSArray *items = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:_extractionFolderURL includingPropertiesForKeys:@[] options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
        if (!items) {
            NSLog(@"[Glitter] Update extraction failed (version %@ at %@) - cannot enumerate %@: %@", _downloadingVersion.version, _downloadingVersion.source.url, _extractionFolderURL.path, error.localizedDescription);
            [self _cleanupDownload];
            return;
        }

        if (items.count != 1) {
            NSLog(@"[Glitter] Update extraction failed (version %@ at %@) - multiple items found in %@: %@", _downloadingVersion.version, _downloadingVersion.source.url, _extractionFolderURL.path, items);
            [self _cleanupDownload];
            return;
        }

        [self _commitReadyToInstallVersion:_downloadingVersion updateURL:items[0]];
        [self _cleanupDownload];
    });
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSInteger code = [(NSHTTPURLResponse *)response statusCode];
    if (code != 200) {
        [connection cancel];
        NSLog(@"[Glitter] Update download failed (version %@ at %@): response code %d", _downloadingVersion.version, _downloadingVersion.source.url, (int)code);
        _downloadingData = nil;
        [self _finishDownload];
        return;
    }

    if (response.expectedContentLength > 0) {
        unsigned long expectedLength = (unsigned long)response.expectedContentLength;
        _downloadingVersion.source.size = expectedLength;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_downloadingData appendData:data];
    _downloadProgress = 100 * (_downloadingData.length / (double)_downloadingVersion.source.size);
    NSLog(@"[Glitter] Downloading version %@ from %@: %.0lf%% done", _downloadingVersion.version, _downloadingVersion.source.url, _downloadProgress);
    [self statusDidChange];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"[Glitter] Update download failed (version %@ at %@): %@", _downloadingVersion.version, _downloadingVersion.source.url, error.localizedDescription);
    _downloadingData = nil;
    [self _finishDownload];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self _finishDownload];
}


#pragma mark - Cleanup

- (void)_deleteUnnecessaryState {
    if (_readyToInstall) {
        // no cleanup while waiting for an update to be installed
        return;
    }

    if ([_updateFolderURL resourceValuesForKeys:@[NSURLIsDirectoryKey] error:NULL]) {
        NSLog(@"[Glitter] Deleting all update-related files");
        [[NSFileManager defaultManager] removeItemAtURL:_updateFolderURL error:NULL];
    }
}


#pragma mark - "Ready to install" state

- (void)_commitReadyToInstallVersion:(GlitterVersion *)release updateURL:(NSURL *)updateURL {
    NSDictionary *state = @{
        GlitterStateFileNameKey: [updateURL lastPathComponent],
        GlitterStateVersionKey: release.version,
        GlitterStateVersionDisplayNameKey: release.versionDisplayName,
        GlitterStateVersionIdentifierKey: release.identifier,
    };

    NSError * __autoreleasing error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:state options:NSJSONWritingPrettyPrinted error:&error];
    if (!data) {
        NSLog(@"[Glitter] Failed to save ready-to-install data - cannot serialize status: %@", error.localizedDescription);
        goto finished;
    }

    [[NSFileManager defaultManager] createDirectoryAtURL:[_statusFileURL URLByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
    BOOL ok = [data writeToURL:_statusFileURL options:NSDataWritingAtomic error:&error];
    if (!ok) {
        NSLog(@"[Glitter] Failed to save ready-to-install data - cannot write status file %@: %@", _statusFileURL.path, error.localizedDescription);
        goto finished;
    }

finished:
    [self _loadReadyToInstallVersionIfAny];
}

- (void)_loadReadyToInstallVersionIfAny {
    NSDictionary *state;

    NSError * __autoreleasing error = nil;
    NSData *data = [NSData dataWithContentsOfURL:_statusFileURL options:0 error:&error];
    if (!data) {
        NSLog(@"[Glitter] Failed to read state: %@", error.localizedDescription);
        goto bail;
    }

    state = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (!state) {
        NSLog(@"[Glitter] Failed to parse state: %@", error.localizedDescription);
        goto bail;
    }

    if (![state isKindOfClass:[NSDictionary class]]) {
        NSLog(@"[Glitter] Failed to parse state: not a dictionary");
        goto bail;
    }

    {
        _readyToInstallVersion = state[GlitterStateVersionKey];
        _readyToInstallVersionDisplayName = state[GlitterStateVersionDisplayNameKey];
        _readyToInstallVersionIdentifier = state[GlitterStateVersionIdentifierKey];
        NSString *fileName = state[GlitterStateFileNameKey];

        if (_readyToInstallVersion.length == 0)
            goto bail;
        if (_readyToInstallVersionIdentifier.length == 0)
            goto bail;
        if (_readyToInstallVersionDisplayName.length == 0)
            goto bail;
        if (fileName.length == 0)
            goto bail;

        if (GlitterCompareVersions(_currentVersion, _readyToInstallVersion) != NSOrderedAscending)
            goto bail;

        _readyToInstallLocalURL = [_extractionFolderURL URLByAppendingPathComponent:fileName];
        NSDictionary *stat = [_readyToInstallLocalURL resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
        if (!stat) {
            NSLog(@"[Glitter] Local update folder not found at %@: %@", _readyToInstallLocalURL.path, error.localizedDescription);
            goto bail;
        }
    }

    _readyToInstall = YES;
    NSLog(@"[Glitter] Ready to install update %@ (\"%@\") at %@", _readyToInstallVersion, _readyToInstallVersionDisplayName, _readyToInstallLocalURL.path);
    goto finished;

bail:
    _readyToInstall = NO;
    _readyToInstallVersion = nil;
    _readyToInstallVersionDisplayName = nil;
    _readyToInstallVersionIdentifier = nil;
    _readyToInstallLocalURL = nil;

finished:
    [self statusDidChange];

    [self _deleteUnnecessaryState];  // now that we know if readyToInstall is NO, we can run the cleanup
}



#pragma mark - Restart

- (BOOL)isReadyToInstall {
    return _readyToInstall;
}

- (NSString *)readyToInstallVersionDisplayName {
    return _readyToInstallVersionDisplayName;
}

- (void)installUpdate {
    if (!_readyToInstall)
        return;
    
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


#pragma mark - Notification

- (void)statusDidChange {
    if (!_notificationScheduled) {
        _notificationScheduled = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            _notificationScheduled = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:GlitterStatusDidChangeNotification object:self];
        });
    }
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:self.automaticCheckingEnabledPreferenceKey]) {
        [self _updateAutomaticCheckingTimer];
    }
}

@end
