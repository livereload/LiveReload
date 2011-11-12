
#import "MainWindow.h"


@implementation MainWindow

- (BOOL)makeFirstResponder:(NSResponder *)aResponder {
    BOOL result = [super makeFirstResponder:aResponder];
    if (result) {
        id delegate = [self delegate];
        if ([delegate respondsToSelector:@selector(window:didChangeFirstResponder:)]) {
            [delegate window:self didChangeFirstResponder:aResponder];
        }
    }
    return result;
}

@end
