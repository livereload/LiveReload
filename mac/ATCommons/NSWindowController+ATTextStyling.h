
#import <Foundation/Foundation.h>

@interface NSWindowController (ATTextStyling)

- (NSShadow *)subtleWhiteShadow;
- (void)styleLabel:(NSControl *)label color:(NSColor *)color shadow:(NSShadow *)shadow;
- (void)styleButton:(NSButton *)button color:(NSColor *)color shadow:(NSShadow *)shadow;
- (void)styleHyperlink:(NSTextField *)label to:(NSURL *)url color:(NSColor *)color shadow:(NSShadow *)shadow;
- (void)styleHyperlink:(NSTextField *)label color:(NSColor *)color shadow:(NSShadow *)shadow;

@end
