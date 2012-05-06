#include "nodeapp_ui_element_osdep_textfield.hh"
#include "nodeapp_ui_element_osdep_utils.hh"


static void StyleHyperlink(NSTextField *label, NSString *string, NSURL *url, NSColor *linkColor);


TextFieldUIElement::TextFieldUIElement(UIElement *parent_context, const char *_id, id view) : ControlUIElement(parent_context, _id, view, [TextFieldUIElementDelegate class]) {
    NSTextField *textField = view_;
    [textField setDelegate:self()];
}

bool TextFieldUIElement::set(const char *property, json_t *value) {
    return ControlUIElement::set(property, value);
}

void TextFieldUIElement::pre_set(json_t *payload) {
    NSString *text = json_object_extract_nsstring(payload, "text");
    NSString *hyperlink_url = json_object_extract_nsstring(payload, "hyperlink-url");
    NSString *hyperlink_color = json_object_extract_nsstring(payload, "hyperlink-color");
    if (text || hyperlink_url) {
        if (!text)
            text = [view_ stringValue];
        if (hyperlink_url) {
            StyleHyperlink(view_, text, [NSURL URLWithString:hyperlink_url], (hyperlink_color ? NSColorFromStringSpec(hyperlink_color) : nil));
        } else {
            [view_ setStringValue:text];
        }
    }
    ControlUIElement::pre_set(payload);
}


@implementation TextFieldUIElementDelegate

#define that ObjCObject::from_id<TextFieldUIElement>(self)

- (void)controlTextDidChange:(NSNotification *)obj {
    that->notify(json_object_1("text-changed", json_nsstring([that->view_ stringValue])));
}

- (void)controlTextDidEndEditing:(NSNotification *)obj {
    that->notify(json_object_1("text-commit", json_nsstring([that->view_ stringValue])));
}

@end


static void StyleHyperlink(NSTextField *label, NSString *string, NSURL *url, NSColor *linkColor) {
    // both are needed, otherwise hyperlink won't accept mousedown
    [label setAllowsEditingTextAttributes:YES];
    [label setSelectable:YES];

    // attributes
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
    NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [paragraphStyle setAlignment:label.alignment];
    if (!linkColor)
        linkColor = label.textColor;
    NSDictionary *linkAttributes = [NSDictionary dictionaryWithObjectsAndKeys:linkColor, NSForegroundColorAttributeName, [NSNumber numberWithInt:NSSingleUnderlineStyle], NSUnderlineStyleAttributeName, url, NSLinkAttributeName, label.font, NSFontAttributeName, shadow, NSShadowAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil];

    NSRange range = [string rangeOfString:@"_["];
    if (range.location == NSNotFound) {
        label.attributedStringValue = [[[NSAttributedString alloc] initWithString:string attributes:linkAttributes] autorelease];
    } else {
        NSString *prefix = [string substringToIndex:range.location];
        string = [string substringFromIndex:range.location + range.length];

        range = [string rangeOfString:@"]_"];
        NSCAssert(range.length > 0, @"Partial hyperlink must contain ]_ marker");
        NSString *link = [string substringToIndex:range.location];
        NSString *suffix = [string substringFromIndex:range.location + range.length];

        NSMutableAttributedString *as = [[[NSMutableAttributedString alloc] init] autorelease];


        [as appendAttributedString:[[[NSAttributedString alloc] initWithString:prefix attributes:[NSDictionary dictionaryWithObjectsAndKeys:label.textColor, NSForegroundColorAttributeName, shadow, NSShadowAttributeName, paragraphStyle, NSParagraphStyleAttributeName, label.font, NSFontAttributeName, nil]] autorelease]];

        [as appendAttributedString:[[[NSAttributedString alloc] initWithString:link attributes:linkAttributes] autorelease]];

        [as appendAttributedString:[[[NSAttributedString alloc] initWithString:suffix attributes:[NSDictionary dictionaryWithObjectsAndKeys:label.textColor, NSForegroundColorAttributeName, shadow, NSShadowAttributeName, paragraphStyle, NSParagraphStyleAttributeName, label.font, NSFontAttributeName, nil]] autorelease]];

        label.attributedStringValue = as;
    }
}
