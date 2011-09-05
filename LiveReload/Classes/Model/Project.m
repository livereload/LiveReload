
#import "ToolOutputWindowController.h"

#import "PluginManager.h"

#import "Project.h"
#import "FSMonitor.h"
#import "FSTreeFilter.h"
#import "FSTree.h"
#import "CommunicationController.h"
#import "Preferences.h"
#import "PluginManager.h"
#import "Compiler.h"
#import "CompilationOptions.h"
#import "FileCompilationOptions.h"
#import "ToolOutput.h"

#import "ATFunctionalStyle.h"


#define PathKey @"path"

NSString *ProjectDidDetectChangeNotification = @"ProjectDidDetectChangeNotification";
NSString *ProjectWillBeginCompilationNotification = @"ProjectWillBeginCompilationNotification";
NSString *ProjectDidEndCompilationNotification = @"ProjectDidEndCompilationNotification";
NSString *ProjectMonitoringStateDidChangeNotification = @"ProjectMonitoringStateDidChangeNotification";
NSString *ProjectNeedsSavingNotification = @"ProjectNeedsSavingNotification";

static NSString *CompilersEnabledMonitoringKey = @"someCompilersEnabled";



@interface Project () <FSMonitorDelegate>

- (void)updateFilter;
- (void)handleCompilationOptionsEnablementChanged:(NSNotification *)notification;

@end


@implementation Project

@synthesize path=_path;
@synthesize dirty=_dirty;
@synthesize lastSelectedPane=_lastSelectedPane;


#pragma mark -
#pragma mark Init/dealloc

- (id)initWithPath:(NSString *)path memento:(NSDictionary *)memento {
    if ((self = [super init])) {
        _path = [path copy];

        _monitor = [[FSMonitor alloc] initWithPath:_path];
        _monitor.delegate = self;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFilter) name:PreferencesFilterSettingsChangedNotification object:nil];
        [self updateFilter];

        _compilerOptions = [[NSMutableDictionary alloc] init];
        _monitoringRequests = [[NSMutableSet alloc] init];

        _lastSelectedPane = [[memento objectForKey:@"last_pane"] copy];

        id raw = [memento objectForKey:@"compilers"];
        if (raw) {
            PluginManager *pluginManager = [PluginManager sharedPluginManager];
            [raw enumerateKeysAndObjectsUsingBlock:^(id uniqueId, id compilerMemento, BOOL *stop) {
                Compiler *compiler = [pluginManager compilerWithUniqueId:uniqueId];
                if (compiler) {
                    [_compilerOptions setObject:[[[CompilationOptions alloc] initWithCompiler:compiler memento:compilerMemento] autorelease] forKey:uniqueId];
                } else {
                    // TODO: save data for unknown compilers and re-add them when creating a memento
                }
            }];
        }

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleCompilationOptionsEnablementChanged:) name:CompilationOptionsEnabledChangedNotification object:nil];
        [self handleCompilationOptionsEnablementChanged:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_path release], _path = nil;
    [_monitor release], _monitor = nil;
    [_compilerOptions release], _compilerOptions = nil;
    [_monitoringRequests release], _monitoringRequests = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Persistence

- (NSDictionary *)memento {
    NSMutableDictionary *memento = [NSMutableDictionary dictionary];
    [memento setObject:[_compilerOptions dictionaryByMappingValuesToSelector:@selector(memento)] forKey:@"compilers"];
    if (_lastSelectedPane)
        [memento setObject:_lastSelectedPane forKey:@"last_pane"];
    return [NSDictionary dictionaryWithDictionary:memento];
}


#pragma mark - Displaying

- (NSString *)displayPath {
    return [_path stringByAbbreviatingWithTildeInPath];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Project(%@)", [self displayPath]];
}

- (NSComparisonResult)compareByDisplayPath:(Project *)another {
    return [self.displayPath compare:another.displayPath];
}


#pragma mark - Filtering

- (void)updateFilter {
    // Cannot ignore hidden files, some guys are using files like .navigation.html as
    // partials. Not sure about directories, but the usual offenders are already on
    // the excludedNames list.
    _monitor.filter.ignoreHiddenFiles = NO;
    _monitor.filter.enabledExtensions = [Preferences sharedPreferences].allExtensions;
    _monitor.filter.excludedNames = [Preferences sharedPreferences].excludedNames;
    [_monitor filterUpdated];
}


#pragma mark -
#pragma mark File System Monitoring

- (void)ceaseAllMonitoring {
    [_monitoringRequests removeAllObjects];
    _monitor.running = NO;
}

- (void)requestMonitoring:(BOOL)monitoringEnabled forKey:(NSString *)key {
    if ([_monitoringRequests containsObject:key] != monitoringEnabled) {
        if (monitoringEnabled) {
//            NSLog(@"%@: requesting monitoring for %@", [self description], key);
            [_monitoringRequests addObject:key];
        } else {
//            NSLog(@"%@: unrequesting monitoring for %@", [self description], key);
            [_monitoringRequests removeObject:key];
        }

        BOOL shouldBeRunning = [_monitoringRequests count] > 0;
        if (shouldBeRunning != _monitor.running) {
            if (shouldBeRunning) {
                NSLog(@"Activated monitoring for %@", [self displayPath]);
            } else {
                NSLog(@"Deactivated monitoring for %@", [self displayPath]);
            }
            _monitor.running = shouldBeRunning;
            [[NSNotificationCenter defaultCenter] postNotificationName:ProjectMonitoringStateDidChangeNotification object:self];
        }
    }
}

- (void)compile:(NSString *)relativePath under:(NSString *)rootPath with:(Compiler *)compiler options:(CompilationOptions *)compilationOptions {
    NSString *path = [rootPath stringByAppendingPathComponent:relativePath];

    CompilationMode mode = compilationOptions.mode;
    if (mode == CompilationModeCompile) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:path])
            return; // don't try to compile deleted files
        FileCompilationOptions *fileOptions = [self optionsForFileAtPath:relativePath in:compilationOptions];
        if (fileOptions.destinationDirectory != nil) {
            NSString *derivedName = [compiler derivedNameForFile:path];
            NSString *derivedPath = [fileOptions.destinationDirectory stringByAppendingPathComponent:derivedName];

            ToolOutput *compilerOutput = nil;
            [compiler compile:relativePath into:derivedPath under:rootPath with:compilationOptions compilerOutput:&compilerOutput];
            if (compilerOutput) {
                compilerOutput.project = self;

                [[[[ToolOutputWindowController alloc] initWithCompilerOutput:compilerOutput key:path] autorelease] show];
            } else {
                [ToolOutputWindowController hideOutputWindowWithKey:path];
            }
        } else {
            NSLog(@"Ignoring %@ because destination directory is not set.", relativePath);
        }
    }
}

- (void)fileSystemMonitor:(FSMonitor *)monitor detectedChangeAtPathes:(NSSet *)pathes {
    NSMutableSet *filtered = [NSMutableSet setWithCapacity:[pathes count]];
    for (NSString *relativePath in pathes) {
        NSString *extension = [relativePath pathExtension];

        BOOL compilerFound = NO;
        for (Compiler *compiler in [PluginManager sharedPluginManager].compilers) {
            if ([compiler.extensions containsObject:extension]) {
                compilerFound = YES;
                CompilationOptions *compilationOptions = [self optionsForCompiler:compiler create:NO];
                if (compilationOptions.mode == CompilationModeCompile) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:ProjectWillBeginCompilationNotification object:self];
                    [self compile:relativePath under:_path with:compiler options:compilationOptions];
                    [[NSNotificationCenter defaultCenter] postNotificationName:ProjectDidEndCompilationNotification object:self];
                    break;
                } else if (compilationOptions.mode == CompilationModeMiddleware) {
                    NSString *derivedName = [compiler derivedNameForFile:relativePath];
                    [filtered addObject:derivedName];
                    NSLog(@"Broadcasting a fake change in %@ instead of %@ because %@ mode is MIDDLEWARE (PRETEND).", derivedName, relativePath, compiler.name);
                    break;
                }
            }
        }

        if (!compilerFound) {
            [filtered addObject:[_path stringByAppendingPathComponent:relativePath]];
        }
    }
    if ([filtered count] == 0) {
        return;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:ProjectDidDetectChangeNotification object:self];
    [[CommunicationController sharedCommunicationController] broadcastChangedPathes:filtered inProject:self];
}

- (FSTree *)tree {
    return _monitor.tree;
}


#pragma mark - Options

- (BOOL)areAnyCompilersEnabled {
    for (CompilationOptions *options in [_compilerOptions allValues]) {
        if (options.mode == CompilationModeCompile) {
            return YES;
        }
    }
    return NO;
}

- (CompilationOptions *)optionsForCompiler:(Compiler *)compiler create:(BOOL)create {
    NSString *uniqueId = compiler.uniqueId;
    CompilationOptions *options = [_compilerOptions objectForKey:uniqueId];
    if (options == nil && create) {
        options = [[[CompilationOptions alloc] initWithCompiler:compiler memento:nil] autorelease];
        [_compilerOptions setObject:options forKey:uniqueId];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
    return options;
}

- (id)enumerateParentFoldersFromFolder:(NSString *)folder with:(id(^)(NSString *folder, NSString *relativePath, BOOL *stop))block {
    BOOL stop = NO;
    NSString *relativePath = @"";
    id result;
    if ((result = block(folder, relativePath, &stop)) != nil)
        return result;
    while (!stop && [[folder pathComponents] count] > 1) {
        relativePath = [[folder lastPathComponent] stringByAppendingPathComponent:relativePath];
        folder = [folder stringByDeletingLastPathComponent];
        if ((result = block(folder, relativePath, &stop)) != nil)
            return result;
    }
    return nil;
}

- (FileCompilationOptions *)optionsForFileAtPath:(NSString *)sourcePath in:(CompilationOptions *)compilationOptions {
    FileCompilationOptions *fileOptions = [compilationOptions optionsForFileAtPath:sourcePath create:YES];
    if (fileOptions.destinationDirectory == nil) {
        // see if we can guess it
        NSString *guessedDirectory = nil;

        // 1) destination file already exists?
        NSString *derivedName = [compilationOptions.compiler derivedNameForFile:sourcePath];
        NSString *derivedPath = [self.tree pathOfFileNamed:derivedName];

        if (derivedPath) {
            guessedDirectory = [derivedPath stringByDeletingLastPathComponent];
            NSLog(@"Guessed output directory for %@ by existing output file %@", sourcePath, derivedPath);
        }

        // 2) other files in the same folder have a common destination path?
        if (guessedDirectory == nil) {
            NSString *sourceDirectory = [sourcePath stringByDeletingLastPathComponent];
            NSArray *otherFiles = [[compilationOptions.compiler pathsOfSourceFilesInTree:self.tree] filteredArrayUsingBlock:^BOOL(id value) {
                return [sourceDirectory isEqualToString:[value stringByDeletingLastPathComponent]];
            }];
            if ([otherFiles count] > 0) {
                NSArray *otherFileOptions = [otherFiles arrayByMappingElementsUsingBlock:^id(id otherFilePath) {
                    return [compilationOptions optionsForFileAtPath:otherFilePath create:NO];
                }];
                NSString *common = [FileCompilationOptions commonOutputDirectoryFor:otherFileOptions];
                if ([common isEqualToString:@"__NONE_SET__"]) {
                    // nothing to figure it from
                } else if (common == nil) {
                    // different directories, something complicated is going on here;
                    // don't try to be too smart and just give up
                    NSLog(@"Refusing to guess output directory for %@ because other files in the same directory have varying output directories", sourcePath);
                    goto skipGuessing;
                } else {
                    guessedDirectory = common;
                    NSLog(@"Guessed output directory for %@ based on configuration of other files in the same directory", sourcePath);
                }
            }
        }

        // 3) are we in a subfolder with one of predefined 'output' names? (e.g. css/something.less)
        if (guessedDirectory == nil) {
            NSSet *magicNames = [NSSet setWithArray:compilationOptions.compiler.expectedOutputDirectoryNames];
            guessedDirectory = [self enumerateParentFoldersFromFolder:[sourcePath stringByDeletingLastPathComponent] with:^(NSString *folder, NSString *relativePath, BOOL *stop) {
                if ([magicNames containsObject:[folder lastPathComponent]]) {
                    NSLog(@"Guessed output directory for %@ to be its own parent folder (%@) based on being located inside a folder with magical name %@", sourcePath, [sourcePath stringByDeletingLastPathComponent], folder);
                    return (id)[sourcePath stringByDeletingLastPathComponent];
                }
                return (id)nil;
            }];
        }

        // 4) is there a sibling directory with one of predefined 'output' names? (e.g. smt/css/ for smt/src/foo/file.styl)
        if (guessedDirectory == nil) {
            NSSet *magicNames = [NSSet setWithArray:compilationOptions.compiler.expectedOutputDirectoryNames];
            guessedDirectory = [self enumerateParentFoldersFromFolder:[sourcePath stringByDeletingLastPathComponent] with:^(NSString *folder, NSString *relativePath, BOOL *stop) {
                NSString *parent = [folder stringByDeletingLastPathComponent];
                NSFileManager *fm = [NSFileManager defaultManager];
                for (NSString *magicName in magicNames) {
                    NSString *possibleDir = [parent stringByAppendingPathComponent:magicName];
                    BOOL isDir = NO;
                    if ([fm fileExistsAtPath:[_path stringByAppendingPathComponent:possibleDir] isDirectory:&isDir])
                        if (isDir) {
                            // TODO: decide whether or not to append relativePath based on existence of other files following the same convention
                            NSString *guess = [possibleDir stringByAppendingPathComponent:relativePath];
                            NSLog(@"Guessed output directory for %@ to be %@ based on a sibling folder with a magical name %@", sourcePath, guess, possibleDir);
                            return (id)guess;
                        }
                }
                return (id)nil;
            }];
        }

        if (guessedDirectory) {
            fileOptions.destinationDirectory = guessedDirectory;
        }
    }
skipGuessing:
    return fileOptions;
}

- (void)handleCompilationOptionsEnablementChanged:(NSNotification *)notification {
    [self requestMonitoring:[self areAnyCompilersEnabled] forKey:CompilersEnabledMonitoringKey];
}


#pragma mark - Paths

- (NSString *)relativePathForPath:(NSString *)path {
    NSString *root = [_path stringByResolvingSymlinksInPath];
    path = [path stringByResolvingSymlinksInPath];

    if ([root isEqualToString:path]) {
        return @"";
    }

    NSArray *rootComponents = [root pathComponents];
    NSArray *pathComponents = [path pathComponents];

    NSInteger pathCount = [pathComponents count];
    NSInteger rootCount = [rootComponents count];
    if (pathCount > rootCount) {
        if ([rootComponents isEqualToArray:[pathComponents subarrayWithRange:NSMakeRange(0, rootCount)]]) {
            return [[pathComponents subarrayWithRange:NSMakeRange(rootCount, pathCount - rootCount)] componentsJoinedByString:@"/"];
        }
    }
    return nil;
}

@end
