
#import "NSWindowController+ATTextStyling.h"


@implementation NSWindowController (ATTextStyling)

- (NSShadow *)subtleWhiteShadow {
    static NSShadow *shadow = nil;
    if (shadow == nil) {
        shadow = [[NSShadow alloc] init];
        [shadow setShadowOffset:NSMakeSize(0, -1)];
        [shadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.33]];
    }
    return shadow;
}

- (NSParagraphStyle *)paragraphStyleForLabel:(NSControl *)label {
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setAlignment:label.alignment];
    return style;
}

- (void)styleLabel:(NSControl *)label color:(NSColor *)color shadow:(NSShadow *)shadow {
    [label setAttributedStringValue:[[NSAttributedString alloc] initWithString:[label stringValue] attributes:[NSDictionary dictionaryWithObjectsAndKeys:color, NSForegroundColorAttributeName, shadow, NSShadowAttributeName, [self paragraphStyleForLabel:label], NSParagraphStyleAttributeName, label.font, NSFontAttributeName, nil]]];
}

- (void)styleButton:(NSButton *)button color:(NSColor *)color shadow:(NSShadow *)shadow {
    [button setAttributedTitle:[[NSAttributedString alloc] initWithString:[button title] attributes:[NSDictionary dictionaryWithObjectsAndKeys:color, NSForegroundColorAttributeName, shadow, NSShadowAttributeName, button.font, NSFontAttributeName, nil]]];
}

- (void)styleHyperlink:(NSTextField *)label to:(NSURL *)url color:(NSColor *)color shadow:(NSShadow *)shadow {
    // both are needed, otherwise hyperlink won't accept mousedown
    [label setAllowsEditingTextAttributes:YES];
    [label setSelectable:YES];

    [label setAttributedStringValue:[[NSAttributedString alloc] initWithString:[label stringValue] attributes:[NSDictionary dictionaryWithObjectsAndKeys:color, NSForegroundColorAttributeName, [NSNumber numberWithInt:NSUnderlineStyleSingle], NSUnderlineStyleAttributeName, url, NSLinkAttributeName, label.font, NSFontAttributeName, shadow, NSShadowAttributeName, [self paragraphStyleForLabel:label], NSParagraphStyleAttributeName, nil]]];
}

- (void)styleHyperlink:(NSTextField *)label color:(NSColor *)color shadow:(NSShadow *)shadow {
    [self styleHyperlink:label to:[NSURL URLWithString:[label stringValue]]color:color shadow:shadow];
}

@end
