
#import <sys/stat.h>
#import "FSTree.h"
#import "FSTreeFilter.h"


struct FSTreeItem {
    CFStringRef name;
    NSInteger parent;
    mode_t st_mode;
    dev_t st_dev;
    ino_t st_ino;
    struct timespec st_mtimespec;
    struct timespec st_ctimespec;
    off_t st_size;
};


static BOOL IsBrokenFolder(NSString *path) {
    FSRef fsref;
    AliasHandle itemAlias;
    HFSUniStr255 targetName;
    HFSUniStr255 volumeName;
    CFStringRef pathString = NULL;
    FSAliasInfoBitmap returnedInInfo;
    FSAliasInfo info;

    char path_buf[1024 * 100];
    char real_path_buf[1024 * 100];

    strcpy(path_buf, [path fileSystemRepresentation]);

    if (strstr(path_buf, "_!LR_BROKEN!_"))
        return YES; // for testing

    if (realpath(path_buf, real_path_buf)) {
        if (0 != strcmp(path_buf, real_path_buf)) {
            return YES;
        }
    }

    // deprecated APIs are required to deal with Apple's bugs
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    FSPathMakeRefWithOptions((unsigned char *)path_buf, kFSPathMakeRefDoNotFollowLeafSymlink, &fsref, NULL);
    FSNewAlias(NULL, &fsref, &itemAlias);
    FSCopyAliasInfo(itemAlias, &targetName, &volumeName, &pathString, &returnedInInfo, &info);
#pragma clang diagnostic pop
    if (pathString) {
        CFStringGetCString(pathString, real_path_buf, sizeof(real_path_buf), kCFStringEncodingUTF8);
        CFRelease(pathString);
        if (0 != strcmp(path_buf, real_path_buf)) {
            return YES;
        }
    }

    return NO;
}


@implementation FSTree

@synthesize rootPath = _rootPath;
@synthesize buildTime = _buildTime;

- (id)initWithPath:(NSString *)rootPath filter:(FSTreeFilter *)filter {
    if ((self = [super init])) {
        _filter = filter;
        _rootPath = [rootPath copy];
        _folders = [NSMutableArray new];

        NSInteger maxItems = [[NSUserDefaults standardUserDefaults] integerForKey:@"MaxMonitoredFilesPerProject"];
        if (maxItems < 2)
            maxItems = 1000000;
        _items = calloc(maxItems, sizeof(struct FSTreeItem));

        NSFileManager *fm = [NSFileManager defaultManager];
        @autoreleasepool {
            NSDate *start = [NSDate date];

            struct stat st;
            if (0 == lstat([rootPath UTF8String], &st)) {
                {
                    struct FSTreeItem *item = &_items[_count++];
                    item->name = (__bridge CFStringRef)@"";
                    item->st_mode = st.st_mode & S_IFMT;
                    item->st_dev = st.st_dev;
                    item->st_ino = st.st_ino;
                    item->st_mtimespec = st.st_mtimespec;
                    item->st_ctimespec = st.st_ctimespec;
                    item->st_size = st.st_size;
                }

                for (NSInteger next = 0; next < _count; ++next) {
                    struct FSTreeItem *item = &_items[next];
                    if (item->st_mode == S_IFDIR) {
                        [_folders addObject:(__bridge NSString *)item->name];
//                    NSLog(@"Listing %@", item->name);
                        NSString *itemPath = [_rootPath stringByAppendingPathComponent:(__bridge NSString *)(item->name)];
                        for (NSString *child in [[fm contentsOfDirectoryAtPath:itemPath error:nil] sortedArrayUsingSelector:@selector(compare:)]) {
                            NSString *subpath = [itemPath stringByAppendingPathComponent:child];
                            if (0 == lstat([subpath UTF8String], &st)) {
                                BOOL isDir = (st.st_mode & S_IFMT) == S_IFDIR;
                                if (![filter acceptsFileName:child isDirectory:isDir])
                                    continue;
                                NSString *relativeChildPath = (CFStringGetLength(item->name) > 0 ? [(__bridge NSString *)item->name stringByAppendingPathComponent:child] : child);
                                if (![filter acceptsFile:relativeChildPath isDirectory:isDir])
                                    continue;
                                if (_count == maxItems) {
                                    NSLog(@"WARNING: Hitting the limit on max monitored files per project. Some files will not be monitored. To increase the limit, use 'defaults write com.livereload.LiveReload MaxMonitoredFilesPerProject %ld'. Current limit is %ld.", MIN(100000, maxItems * 5), maxItems);
                                    break;
                                }
                                struct FSTreeItem *subitem = &_items[_count++];
                                subitem->parent = next;
                                subitem->name = CFBridgingRetain(relativeChildPath);
                                subitem->st_mode = st.st_mode & S_IFMT;
                                subitem->st_dev = st.st_dev;
                                subitem->st_ino = st.st_ino;
                                subitem->st_mtimespec = st.st_mtimespec;
                                subitem->st_ctimespec = st.st_ctimespec;
                                subitem->st_size = st.st_size;
                            }
                        }
                    }
                }
            }


            NSDate *end = [NSDate date];
            _buildTime = [end timeIntervalSinceReferenceDate] - [start timeIntervalSinceReferenceDate];
            NSLog(@"Scanned %d items in %.3lfs in directory %@", (int)_count, _buildTime, rootPath);
        }

        [_folders sortUsingSelector:@selector(compare:)];
    }
    return self;
}

- (void)dealloc {
    struct FSTreeItem *end = _items + _count;
    for (struct FSTreeItem *cur = _items; cur < end; ++cur) {
        CFRelease(cur->name);
    }
    free(_items);
}

- (NSSet *)differenceFrom:(FSTree *)previous {
    NSMutableSet *differences = [NSMutableSet set];

    struct FSTreeItem *previtems = previous->_items;
    NSInteger prevcount = previous->_count;

    NSInteger *corresponding = malloc(_count * sizeof(NSInteger));
    NSInteger *rcorresponding = malloc(prevcount * sizeof(NSInteger));

    if (corresponding == NULL) {
        NSLog(@"** Error: malloc of corresponding[] returned NULL, count=%ld, prevcount=%ld, previous=%p, previtems=%p", _count, prevcount, previous, previtems);
        return [NSSet set];
    }
    if (rcorresponding == NULL) {
        NSLog(@"** Error: malloc of rcorresponding[] returned NULL, count=%ld, prevcount=%ld, previous=%p, previtems=%p", _count, prevcount, previous, previtems);
        return [NSSet set];
    }

    memset(corresponding, -1, _count * sizeof(NSInteger));
    memset(rcorresponding, -1, prevcount * sizeof(NSInteger));

    corresponding[0] = 0;
    rcorresponding[0] = 0;

    NSInteger i = 1, j = 1;
    while (i < _count && j < prevcount) {
        NSInteger cp = corresponding[_items[i].parent];
        if (cp < 0) {
            NSLog(@"%@ is a subitem of a new item", _items[i].name);
            corresponding[i] = -1;
            ++i;
        } else if (previtems[j].parent < cp) {
            NSLog(@"%@ is a deleted item", previtems[j].name);
            rcorresponding[j] = -1;
            ++j;
        } else if (previtems[j].parent > cp) {
            NSLog(@"%@ is a new item", _items[i].name);
            corresponding[i] = -1;
            ++i;
        } else {
            NSComparisonResult r = [(__bridge NSString *)_items[i].name compare:(__bridge NSString *)previtems[j].name];
            if (r == 0) {
                // same item! compare mod times
                if (_items[i].st_mode == previtems[j].st_mode && _items[i].st_dev == previtems[j].st_dev && _items[i].st_ino == previtems[j].st_ino && _items[i].st_mtimespec.tv_sec == previtems[j].st_mtimespec.tv_sec && _items[i].st_mtimespec.tv_nsec == previtems[j].st_mtimespec.tv_nsec && _items[i].st_ctimespec.tv_sec == previtems[j].st_ctimespec.tv_sec && _items[i].st_ctimespec.tv_nsec == previtems[j].st_ctimespec.tv_nsec && _items[i].st_size == previtems[j].st_size) {
                    // unchanged
//                    NSLog(@"%@ is unchanged item", _items[i].name);
                } else {
                    // changed
                    NSLog(@"%@ is changed item", _items[i].name);
                    if (_items[i].st_mode == S_IFREG || previtems[j].st_mode == S_IFREG) {
                        [differences addObject:(__bridge NSString *)_items[i].name];
                    }
                }
                corresponding[i] = j;
                rcorresponding[j] = i;
                ++i;
                ++j;
            } else if (r > 0) {
                // i is after j => we need to advance j => j is deleted
                NSLog(@"%@ is a deleted item", previtems[j].name);
                rcorresponding[j] = -1;
                ++j;
            } else /* if (r < 0) */ {
                // i is before j => we need to advance i => i is new
                NSLog(@"%@ is a new item", _items[i].name);
                corresponding[i] = -1;
                ++i;
            }
        }
    }
    // for any tail left, we've already filled it in with -1's

    for (i = 0; i < _count; i++) {
        if (corresponding[i] < 0) {
            if (_items[i].st_mode == S_IFREG) {
                [differences addObject:(__bridge NSString *)_items[i].name];
            }
        }
    }
    for (j = 0; j < prevcount; j++) {
        if (rcorresponding[j] < 0) {
            if (previtems[j].st_mode == S_IFREG) {
                [differences addObject:(__bridge NSString *)previtems[j].name];
            }
        }
    }

    free(corresponding);
    free(rcorresponding);

    return differences;
}


#pragma mark - Querying

- (NSArray *)filePaths {
    return [self pathsOfFilesMatching:^BOOL(NSString *name) {
        return YES;
    }];
}

- (NSArray *)folderPaths {
    return _folders;
}

- (BOOL)containsFileNamed:(NSString *)fileName {
    return nil != [self pathOfFileNamed:fileName];
}

- (NSString *)pathOfFileNamed:(NSString *)fileName {
    @autoreleasepool {
        struct FSTreeItem *end = _items + _count;
        for (struct FSTreeItem *cur = _items; cur < end; ++cur) {
            if ([[(__bridge NSString *)cur->name lastPathComponent] isEqualToString:fileName]) {
                return (__bridge NSString *)cur->name;
            }
        }
    }
    return nil;
}

- (NSString *)pathOfBestFileMatchingPathSuffix:(NSString *)pathSuffix preferringSubtree:(NSString *)subtreePath {
    // avoid edge cases
    if ([pathSuffix pathComponents].count == 1)
        return [self pathOfFileNamed:pathSuffix];

    NSString *name = [pathSuffix lastPathComponent];
    NSArray *suffix = [[pathSuffix stringByDeletingLastPathComponent] pathComponents];

    NSString *bestMatch = nil;
    NSInteger bestScore = -1;
    
    NSArray *subtreeComponents = [subtreePath pathComponents];

    for (NSString *path in [self pathsOfFilesNamed:name]) {
        NSArray *components = [[path stringByDeletingLastPathComponent] pathComponents];
        
        NSInteger score = 0;
        NSInteger common = MIN(components.count, suffix.count);

        // score is the number of matching path components, not counting the name itself
        while (score < common && [[components subarrayWithRange:NSMakeRange(components.count - (score+1), (score+1))] isEqualToArray:[suffix subarrayWithRange:NSMakeRange(suffix.count - (score+1), (score+1))]])
            ++score;

        // adjust score to give the given subtree a preference
        score *= 10;
        if (subtreePath.length && components.count >= subtreeComponents.count && [[components subarrayWithRange:NSMakeRange(0, subtreeComponents.count)] isEqualToArray:subtreeComponents]) {
            score += 5;
        }
        
        if (score > bestScore) {
            bestMatch = path;
            bestScore = score;
        }
    }
    
    return bestMatch;
}

- (NSArray *)pathsOfFilesNamed:(NSString *)fileName {
    NSMutableArray *result = [NSMutableArray array];
    @autoreleasepool {
        struct FSTreeItem *end = _items + _count;
        for (struct FSTreeItem *cur = _items; cur < end; ++cur) {
            if (cur->st_mode == S_IFREG && [[(__bridge NSString *)cur->name lastPathComponent] isEqualToString:fileName]) {
                [result addObject:(__bridge NSString *)cur->name];
            }
        }
        return result;
    }
}

- (NSArray *)pathsOfFilesMatching:(BOOL (^)(NSString *))filter {
    NSMutableArray *result = [NSMutableArray array];
    @autoreleasepool {
        struct FSTreeItem *end = _items + _count;
        for (struct FSTreeItem *cur = _items; cur < end; ++cur) {
            if (cur->st_mode == S_IFREG && filter((__bridge NSString *)cur->name)) {
                [result addObject:(__bridge NSString *)cur->name];
            }
        }
        return result;
    }
}

- (NSArray *)brokenPaths {
    if (IsBrokenFolder(_rootPath)) {
        NSString *topmostBrokenFolder = _rootPath;
        while ([[topmostBrokenFolder pathComponents] count] > 1) {
            NSString *nextFolderToTry = [topmostBrokenFolder stringByDeletingLastPathComponent];
            if (!IsBrokenFolder(nextFolderToTry))
                break;
            topmostBrokenFolder = nextFolderToTry;
        }
        return [NSArray arrayWithObject:topmostBrokenFolder];
    }

    NSMutableArray *result = [NSMutableArray array];
    @autoreleasepool {

        struct FSTreeItem *end = _items + _count;
        for (struct FSTreeItem *cur = _items; cur < end; ++cur) {
            if (cur->st_mode == S_IFDIR) {
                if (IsBrokenFolder([_rootPath stringByAppendingPathComponent:(__bridge NSString *)cur->name])) {
                    // ignore children of already reported folders
                    for (NSString *peer in result) {
                        if ((NSUInteger)CFStringGetLength(cur->name) > [peer length] && [(__bridge NSString *)cur->name characterAtIndex:[peer length]] == '/' && [[(__bridge NSString *)cur->name substringToIndex:[peer length]] isEqualToString:peer]) {
                            goto skip;
                        }
                    }
                    [result addObject:(__bridge NSString *)cur->name];
                skip: ;
                }
            }
        }

        // make the paths absolute
        NSString *root = [_rootPath stringByAbbreviatingWithTildeInPath];
        NSInteger count = [result count];
        for (NSInteger index = 0; index < count; ++index) {
            NSString *item = [result objectAtIndex:index];
            [result replaceObjectAtIndex:index withObject:[root stringByAppendingPathComponent:item]];
        }

        return result;
    }
}

@end
