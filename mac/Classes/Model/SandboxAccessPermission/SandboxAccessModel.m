
#import "SandboxAccessModel.h"
@import LRCommons;


@implementation SandboxAccessModel {
    NSMutableArray *_urls;
    NSMutableArray *_bookmarks;

    ATCoalescedState _savingState;
}

- (id)initWithDataFileURL:(NSURL *)dataFileURL {
    self = [super init];
    if (self) {
        _urls = [NSMutableArray new];
        _bookmarks = [NSMutableArray new];

        _dataFileURL = dataFileURL;
        [self _load];
    }
    return self;
}

- (NSArray *)accessibleURLs {
    return [_urls filteredArrayUsingBlock:^BOOL(id value) {
        return value != [NSNull null];
    }];
}

- (void)addURL:(NSURL *)url {
    NSError * __autoreleasing error = nil;

    [_urls addObject:url];

    NSLog(@"Added sandbox exception: %@", url.path);
    if (![url startAccessingSecurityScopedResource]) {
        NSLog(@"Failed to activate sandbox exception at %@", url.path);
    }

    NSData *bookmark = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:@[] relativeToURL:nil error:&error];
    if (!bookmark) {
        NSLog(@"Error creating bookmark for %@: %@ - %ld - %@", url, error.domain, (long)error.code, error.localizedDescription);
        [_bookmarks addObject:[NSNull null]];
    } else {
        NSString *encodedBookmark = [bookmark base64EncodedString];
        [_bookmarks addObject:encodedBookmark];
        [self _save];
    }
}


#pragma mark - Granting access

- (NSURL *)grantAccessToURL:(NSURL *)url writeAccess:(BOOL)writeAccess title:(NSString *)title message:(NSString *)message {
    ATPathAccessibility accessibility = ATCheckPathAccessibility(url);
    if (accessibility == ATPathAccessibilityAccessible)
        return url;

    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanCreateDirectories:NO];
    [openPanel setTitle:title];
    [openPanel setMessage:message];
    [openPanel setPrompt:@"Allow Access"];
    [openPanel setCanChooseFiles:NO];
    [openPanel setTreatsFilePackagesAsDirectories:YES];
    [openPanel setDirectoryURL:url];

    NSInteger result = [openPanel runModal];
    if (result == NSFileHandlingPanelOKButton) {
        NSURL *url = [openPanel URL];

        if (ATCheckPathAccessibility(url) == ATPathAccessibilityAccessible) {
            [self addURL:url];
            return url;
        }
    }

    return nil;
}


#pragma mark - Load/save

- (void)_load {
    NSError * __autoreleasing error = nil;

    NSData *data = [NSData dataWithContentsOfURL:_dataFileURL options:0 error:&error];
    if (!data) {
        if (!([error.domain isEqualToString:NSCocoaErrorDomain] && error.code == NSFileReadNoSuchFileError)) {
            NSLog(@"Error reading %@: %@ - %ld - %@", _dataFileURL, error.domain, (long)error.code, error.localizedDescription);
        }
        return;
    }

    NSArray *encodedBookmarks = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (!encodedBookmarks) {
        NSLog(@"Error parsing %@: %@ - %ld - %@", _dataFileURL, error.domain, (long)error.code, error.localizedDescription);
        return;
    }

    for (__strong NSString *encodedBookmark in encodedBookmarks) {
        NSData *bookmark = [NSData dataFromBase64String:encodedBookmark];
        if (!bookmark.length)
            continue;

        BOOL stale = NO;
        NSURL *url = [NSURL URLByResolvingBookmarkData:bookmark options:NSURLBookmarkResolutionWithSecurityScope|NSURLBookmarkResolutionWithoutUI relativeToURL:nil bookmarkDataIsStale:&stale error:&error];
        if (!url) {
            [_urls addObject:[NSNull null]];
        } else {
            [_urls addObject:url];

            NSLog(@"Loaded sandbox exception: %@", url.path);
            if (![url startAccessingSecurityScopedResource]) {
                NSLog(@"Failed to activate sandbox exception at %@", url.path);
            }

            if (stale) {
                NSData *bookmark = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:@[] relativeToURL:nil error:&error];
                if (!bookmark) {
                    NSLog(@"Error regenerating bookmark for %@: %@ - %ld - %@", url, error.domain, (long)error.code, error.localizedDescription);
                } else {
                    encodedBookmark = [bookmark base64EncodedString];
                }
            }
        }

        [_bookmarks addObject:encodedBookmark];
    }
}

- (void)_save {
    AT_dispatch_coalesced(&_savingState, 10, ^(dispatch_block_t done) {
        NSArray *encodedBookmarks = [[_bookmarks filteredArrayUsingBlock:^BOOL(id value) {
            return value != [NSNull null];
        }] copy];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSError * __autoreleasing error = nil;
            NSData *data = [NSJSONSerialization dataWithJSONObject:encodedBookmarks options:NSJSONWritingPrettyPrinted error:0];
            if (!data) {
                NSLog(@"Error serializing bookmarks: %@ - %ld - %@", error.domain, (long)error.code, error.localizedDescription);
                done();
                return;
            }

            if (![[NSFileManager defaultManager] fileExistsAtPath:[_dataFileURL URLByDeletingLastPathComponent].path]) {
                BOOL ok = [[NSFileManager defaultManager] createDirectoryAtURL:[_dataFileURL URLByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
                if (!ok) {
                    NSLog(@"Cannot create directory at %@: %@ - %ld - %@", [_dataFileURL URLByDeletingLastPathComponent], error.domain, (long)error.code, error.localizedDescription);
                }
            }

            BOOL ok = [data writeToURL:_dataFileURL options:NSDataWritingAtomic error:&error];
            if (!ok) {
                NSLog(@"Error writing bookmarks to %@: %@ - %ld - %@", _dataFileURL, error.domain, (long)error.code, error.localizedDescription);
                done();
                return;
            }

            done();
        });
    });
}

@end
