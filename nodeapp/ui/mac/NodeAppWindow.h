
#import <AppKit/AppKit.h>


@interface NodeAppWindow : NSWindow
@end


@interface NSObject (NodeAppWindowDelegate)

- (void)window:(NSWindow *)window didChangeFirstResponder:(NSResponder *)responder;

@end
