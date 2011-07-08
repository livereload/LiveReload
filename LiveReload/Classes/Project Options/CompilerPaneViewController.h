
#import <Cocoa/Cocoa.h>
#import "PaneViewController.h"


@class Compiler;
@class CompilationOptions;


@interface CompilerPaneViewController : PaneViewController {
@private
    Compiler               *_compiler;
    CompilationOptions     *_options;
}

- (id)initWithProject:(Project *)project compiler:(Compiler *)compiler;

@property (nonatomic, readonly) Compiler *compiler;
@property (nonatomic, readonly) CompilationOptions *options;


@end
