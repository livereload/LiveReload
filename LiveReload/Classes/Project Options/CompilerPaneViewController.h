
#import <Cocoa/Cocoa.h>
#import "PaneViewController.h"


@class Compiler;
@class CompilationOptions;


@interface CompilerPaneViewController : PaneViewController {
@private
    Compiler               *_compiler;
    CompilationOptions     *_options;
    NSArray                *_fileOptions;
    NSButtonCell *_compileModeButton;
    NSButtonCell *_middlewareModeButton;

    NSObjectController     *_objectController;
    NSArrayController      *_fileOptionsArrayController;
}

- (id)initWithProject:(Project *)project compiler:(Compiler *)compiler;

@property (nonatomic, readonly) Compiler *compiler;
@property (nonatomic, readonly) CompilationOptions *options;
@property (nonatomic, readonly) BOOL hideOutputDirectoryControls;

@property (assign) IBOutlet NSObjectController *objectController;
@property (assign) IBOutlet NSArrayController *fileOptionsArrayController;

@property (nonatomic, readonly) NSArray *fileOptions;

@property (assign) IBOutlet NSButtonCell *compileModeButton;
@property (assign) IBOutlet NSButtonCell *middlewareModeButton;


@end
