
#import <Cocoa/Cocoa.h>


@class ToolError;
@class Editor;


@interface ToolErrorWindowController : NSWindowController {
    ToolError             *_compilerError;
    NSString              *_key;

    NSTextField           *_fileNameLabel;
    NSTextField           *_lineNumberLabel;
    NSTextField           *_messageLabel;
    NSPopUpButton         *_actionButton;
    NSButton              *_jumpToErrorButton;

    ToolErrorWindowController *_previousWindowController;
    BOOL                   _appearing;
    BOOL                   _suicidal;

    Editor                *_editor;
}

- (id)initWithCompilerError:(ToolError *)compilerError key:(NSString *)key;

@property (assign) IBOutlet NSTextField *fileNameLabel;
@property (assign) IBOutlet NSTextField *lineNumberLabel;
@property (assign) IBOutlet NSTextField *messageLabel;
@property (assign) IBOutlet NSPopUpButton *actionButton;
@property (assign) IBOutlet NSButton *jumpToErrorButton;

- (void)show;

+ (void)hideErrorWindowWithKey:(NSString *)key;

@end
