
#import "CompilerPaneViewController.h"

#import "Project.h"
#import "Compiler.h"
#import "CompilationOptions.h"
#import "FileCompilationOptions.h"

#import "FSTree.h"


@interface CompilerPaneViewController ()

- (void)updateFileOptions;
- (void)handleProjectDidDetectChange:(NSNotification *)notification;

@end



@implementation CompilerPaneViewController

@synthesize compiler=_compiler;
@synthesize objectController = _objectController;
@synthesize fileOptions=_fileOptions;


#pragma mark - init/dealloc

- (id)initWithProject:(Project *)project compiler:(Compiler *)compiler {
    self = [super initWithNibName:@"CompilerPaneViewController" bundle:nil project:project];
    if (self) {
        _compiler = [compiler retain];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectDidDetectChange:) name:ProjectDidDetectChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_compiler release], _compiler = nil;
    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@(%@, %@)", NSStringFromClass([self class]), _project.displayPath, _compiler.name];
}


#pragma mark - Pane options

- (NSString *)title {
    return _compiler.name;
}

- (BOOL)isActive {
    return self.options.enabled;
}

- (void)setActive:(BOOL)active {
    self.options.enabled = active;
}


#pragma mark - Pane lifecycle

- (NSString *)monitoringKey {
    return [NSString stringWithFormat:@"compilerOptionsOpen:%@", _compiler.uniqueId];
}

- (void)paneWillShow {
    [super paneWillShow];
    [_project requestMonitoring:YES forKey:[self monitoringKey]];
    [self updateFileOptions];
}

- (void)paneDidShow {
    [super paneDidShow];
}

- (void)paneWillHide {
    [_objectController commitEditing];
    [super paneWillHide];
}

- (void)paneDidHide {
    [_project requestMonitoring:NO forKey:[self monitoringKey]];
}


#pragma mark - Compilation options

- (CompilationOptions *)options {
    if (_options == nil) {
        _options = [[_project optionsForCompiler:_compiler create:YES] retain];
    }
    return _options;
}

- (void)updateFileOptions {
    CompilationOptions *options = self.options;
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (NSString *sourcePath in [_compiler pathsOfSourceFilesInTree:_project.tree]) {
        FileCompilationOptions *fileOptions = [options optionsForFileAtPath:sourcePath create:YES];
        if (fileOptions.destinationDirectory == nil) {
            NSString *derivedName = [_compiler derivedNameForFile:sourcePath];
            NSString *guessedDestinationPath = [_project.tree pathOfFileNamed:derivedName];
            if (guessedDestinationPath) {
                fileOptions.destinationDirectory = [guessedDestinationPath stringByDeletingLastPathComponent];
            }
        }
        [array addObject:fileOptions];
    }
    [self willChangeValueForKey:@"fileOptions"];
    _fileOptions = [[NSArray alloc] initWithArray:array];
    [self didChangeValueForKey:@"fileOptions"];
}

- (void)handleProjectDidDetectChange:(NSNotification *)notification {
    if (notification.object == _project) {
        [self updateFileOptions];
    }
}

@end
