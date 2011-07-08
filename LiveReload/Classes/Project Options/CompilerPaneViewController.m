
#import "CompilerPaneViewController.h"

#import "Project.h"
#import "Compiler.h"
#import "CompilationOptions.h"


@implementation CompilerPaneViewController

@synthesize compiler=_compiler;


#pragma mark - init/dealloc

- (id)initWithProject:(Project *)project compiler:(Compiler *)compiler {
    self = [super initWithNibName:@"CompilerPaneViewController" bundle:nil project:project];
    if (self) {
        _compiler = [compiler retain];
    }
    return self;
}

- (void)dealloc {
    [_compiler release], _compiler = nil;
    [super dealloc];
}


#pragma mark - Options

- (CompilationOptions *)options {
    if (_options == nil) {
        _options = [[_project optionsForCompiler:_compiler create:YES] retain];
    }
    return _options;
}

- (NSString *)title {
    return _compiler.name;
}

- (BOOL)isActive {
    return self.options.enabled;
}

- (void)setActive:(BOOL)active {
    self.options.enabled = active;
}

@end
