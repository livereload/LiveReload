
#include "eventbus.h"
#include "console.h"

#import "TerminalView.h"



#define kTextMarginHorz 5
#define kTextMarginVert 10



void MyDrawNinePartImage(CGRect frame, NSImage *image, CGFloat topSlice, CGFloat rightSlice, CGFloat bottomSlice, CGFloat leftSlice, NSCompositingOperation operation, CGFloat fraction) {
    CGSize frameSize = frame.size;
    CGSize imageSize = [image size];

    // top left
    [image drawInRect:NSMakeRect(0, frameSize.height - topSlice, leftSlice, topSlice) fromRect:NSMakeRect(0, imageSize.height - topSlice, leftSlice, topSlice) operation:operation fraction:fraction];
    // top right
    [image drawInRect:NSMakeRect(frameSize.width - rightSlice, frameSize.height - topSlice, leftSlice, topSlice) fromRect:NSMakeRect(imageSize.width - rightSlice, imageSize.height - topSlice, leftSlice, topSlice) operation:operation fraction:fraction];
    // bottom left
    [image drawInRect:NSMakeRect(0, 0, leftSlice, bottomSlice) fromRect:NSMakeRect(0, 0, leftSlice, bottomSlice) operation:operation fraction:fraction];
    // bottom right
    [image drawInRect:NSMakeRect(frameSize.width - rightSlice, 0, leftSlice, bottomSlice) fromRect:NSMakeRect(imageSize.width - rightSlice, 0, leftSlice, bottomSlice) operation:operation fraction:fraction];

    // left
    [image drawInRect:NSMakeRect(0, bottomSlice, leftSlice, frameSize.height - bottomSlice - topSlice) fromRect:NSMakeRect(0, bottomSlice, leftSlice, imageSize.height - bottomSlice - topSlice) operation:operation fraction:fraction];
    // right
    [image drawInRect:NSMakeRect(frameSize.width - rightSlice, bottomSlice, leftSlice, frameSize.height - bottomSlice - topSlice) fromRect:NSMakeRect(imageSize.width - rightSlice, bottomSlice, leftSlice, imageSize.height - bottomSlice - topSlice) operation:operation fraction:fraction];

    // top
    [image drawInRect:NSMakeRect(leftSlice, frameSize.height - topSlice, frameSize.width - leftSlice - rightSlice, topSlice) fromRect:NSMakeRect(leftSlice, imageSize.height - topSlice, imageSize.width - leftSlice - rightSlice, topSlice) operation:operation fraction:fraction];
    // bottom
    [image drawInRect:NSMakeRect(leftSlice, 0, frameSize.width - leftSlice - rightSlice, bottomSlice) fromRect:NSMakeRect(leftSlice, 0, imageSize.width - leftSlice - rightSlice, bottomSlice) operation:operation fraction:fraction];

    // center
    [image drawInRect:NSMakeRect(leftSlice, bottomSlice, frameSize.width - leftSlice - rightSlice, frameSize.height - bottomSlice - topSlice) fromRect:NSMakeRect(leftSlice, bottomSlice, imageSize.width - leftSlice - rightSlice, imageSize.height - bottomSlice - topSlice) operation:operation fraction:fraction];
}



@interface TerminalStripeView : NSView
@end



@interface TerminalView ()

- (void)update;

@end




@implementation TerminalStripeView {
    NSImage               *_stripeImage;
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _stripeImage = [[NSImage imageNamed:@"TerminalStripes.png"] retain];
    }
    return self;
}

- (void)dealloc {
    [_stripeImage release], _stripeImage = nil;
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect {
    NSDrawNinePartImage([self bounds], nil, nil, nil, nil, _stripeImage, nil, nil, nil, nil, NSCompositeSourceOver, 1.0, NO);
}

- (NSView *)hitTest:(NSPoint)aPoint {
    return nil;
}

@end



static void on_console_message_added(event_name_t event, const char *message, TerminalView *view) {
    [view update];
}


@implementation TerminalView {
    NSTextView            *_textView;
    NSImage               *_backgroundImage;
    NSImage               *_glareImage;
}

- (NSRect)textBounds {
    CGSize size = [self bounds].size;
    return NSMakeRect(kTextMarginHorz, kTextMarginVert, size.width - 2*kTextMarginHorz, size.height - 2*kTextMarginVert);
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        NSRect textBounds = [self textBounds];
        NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:textBounds];
        NSSize contentSize = [scrollView contentSize];

        [scrollView setBorderType:NSNoBorder];
        [scrollView setHasVerticalScroller:YES];
        [scrollView setHasHorizontalScroller:NO];
        [scrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [scrollView setDrawsBackground:NO];

        _textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height)];
        [_textView setMinSize:NSMakeSize(0.0, contentSize.height)];
        [_textView setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
        [_textView setVerticallyResizable:YES];
        [_textView setHorizontallyResizable:NO];
        [_textView setAutoresizingMask:NSViewWidthSizable];
        [[_textView textContainer] setContainerSize:NSMakeSize(contentSize.width, FLT_MAX)];
        [[_textView textContainer] setWidthTracksTextView:YES];

        [_textView setEditable:NO];
        [_textView setSelectable:YES];
        [_textView setDrawsBackground:NO];
        [_textView setTextColor:[NSColor whiteColor]];
        [_textView setFont:[NSFont fontWithName:@"Monaco" size:13]];
        [_textView setString:[NSString stringWithUTF8String:console_get()]];

        [scrollView setDocumentView:_textView];

        [self addSubview:scrollView];

        TerminalStripeView *stripeView = [[TerminalStripeView alloc] initWithFrame:textBounds];
        [stripeView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [self addSubview:stripeView];

        _backgroundImage = [[NSImage imageNamed:@"TerminalBackgroundSquare.png"] retain];
        _glareImage = [[NSImage imageNamed:@"TerminalGlare.png"] retain];

        eventbus_subscribe(console_message_added_event, (event_handler_t)on_console_message_added, self);
        [self update];
    }
    return self;
}

- (void)dealloc {
    eventbus_unsubscribe(console_message_added_event, (event_handler_t)on_console_message_added, self);
    [_backgroundImage release], _backgroundImage = nil;
    [_glareImage release], _glareImage = nil;
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect {
    [[NSGraphicsContext currentContext] saveGraphicsState];

    NSRect bounds = [self bounds];

    MyDrawNinePartImage(bounds, _backgroundImage, 30, 17, 17, 17, NSCompositeSourceOver, 1.0);

    NSRect textBounds = [self textBounds];
    CGSize glareSize = _glareImage.size;
    [_glareImage drawInRect:textBounds fromRect:NSMakeRect(0, 0, glareSize.width, glareSize.height) operation:NSCompositeSourceOver fraction:0.8];

    [[NSGraphicsContext currentContext] restoreGraphicsState];
}

- (void)update {
    [_textView setString:[NSString stringWithUTF8String:console_get()]];
    [_textView scrollToEndOfDocument:nil];
}

@end
