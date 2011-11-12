
#import <AppKit/AppKit.h>


@interface MainWindow : NSWindow
@end


@interface NSObject (MainWindowDelegate)

- (void)window:(NSWindow *)window didChangeFirstResponder:(NSResponder *)responder;

@end
