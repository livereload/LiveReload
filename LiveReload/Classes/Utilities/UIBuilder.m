
#import "UIBuilder.h"



typedef enum {
    ControlTypeNone,
    ControlTypeCheckBox,
    ControlTypePopUp,
    ControlTypeEdit,
    ControlTypeFullWidthLabel,
    ControlTypeRightLabel,
} ControlType;
enum { ControlTypeCount = 6 };



#define kPopUpControlX 150
#define kPopUpControlWidth 281
#define kPopUpControlHeight 26
#define kCheckBoxX 151
#define kCheckBoxWidth 311
#define kCheckBoxHeight 18
#define kEditX 153
#define kEditWidth 275
#define kEditHeight 22
#define kLabelX 17
#define kLabelWidth 131
#define kLabelHeight 17
#define kFullWidthLabelWidth (kCheckBoxX + kCheckBoxWidth - kLabelX)
#define kRightLabelX 150
#define kRightLabelWidth (kCheckBoxX + kCheckBoxWidth - kRightLabelX)



typedef struct {
    ControlType type;
    CGFloat labelOffset;
    CGFloat bottomMargins[ControlTypeCount];
} ControlTypeInfo;

static ControlTypeInfo CONTROL_TYPE_INFO[] = {
    {
        .type = ControlTypeNone,
        .labelOffset = 0,
        .bottomMargins = { 0 },
    },
    {
        .type = ControlTypeCheckBox,
        .labelOffset = 1,
        .bottomMargins = {
            [ControlTypeNone] = 0,
            [ControlTypeCheckBox] = 20 - kCheckBoxHeight,
            [ControlTypePopUp] = 30 - kPopUpControlHeight,
            [ControlTypeEdit] = 28 - kEditHeight,
            [ControlTypeFullWidthLabel] = 0,
            [ControlTypeRightLabel] = 0,
        },
    },
    {
        .type = ControlTypePopUp,
        .labelOffset = 6,
        .bottomMargins = {
            [ControlTypeNone] = 0,
            [ControlTypeCheckBox] = 22 - kCheckBoxHeight,
            [ControlTypePopUp] = 26 - kPopUpControlHeight,
            [ControlTypeEdit] = 27 - kEditHeight,
            [ControlTypeFullWidthLabel] = 0,
            [ControlTypeRightLabel] = 0,
        },
    },
    {
        .type = ControlTypeEdit,
        .labelOffset = 3,
        .bottomMargins = {
            [ControlTypeNone] = 0,
            [ControlTypeCheckBox] = 24 - kCheckBoxHeight,
            [ControlTypePopUp] = 32 - kPopUpControlHeight,
            [ControlTypeEdit] = 32 - kEditHeight,
            [ControlTypeFullWidthLabel] = 0,
            [ControlTypeRightLabel] = 0,
        },
    },
    {
        .type = ControlTypeFullWidthLabel,
        .labelOffset = 0,
        .bottomMargins = {
            [ControlTypeNone] = 0,
            [ControlTypeCheckBox] = 0,
            [ControlTypePopUp] = 0,
            [ControlTypeEdit] = 0,
            [ControlTypeFullWidthLabel] = 0,
            [ControlTypeRightLabel] = 0,
        },
    },
    {
        .type = ControlTypeRightLabel,
        .labelOffset = 0,
        .bottomMargins = {
            [ControlTypeNone] = 0,
            [ControlTypeCheckBox] = 0,
            [ControlTypePopUp] = 0,
            [ControlTypeEdit] = 0,
            [ControlTypeFullWidthLabel] = 0,
            [ControlTypeRightLabel] = 0,
        },
    },
};



#define LAST CONTROL_TYPE_INFO[_lastControlType]



@interface UIBuilder () {
    NSWindow              *_window;

    CGFloat                _nextY;
    CGFloat                _lastControlY;
    ControlType            _lastControlType;
    BOOL                   _labelAdded;
    NSMutableArray        *_controls;
}

- (void)addControl:(NSView *)control ofType:(ControlType)type;

@end



@implementation UIBuilder

@synthesize labelAdded=_labelAdded;


#pragma mark - Init/dealloc

- (id)initWithWindow:(NSWindow *)window {
    self = [super init];
    if (self) {
        _window = [window retain];
    }
    return self;
}

- (void)dealloc {
    [_window release], _window = nil;
    [super dealloc];
}


#pragma mark - Public methods

- (void)buildUIWithTopInset:(CGFloat)topInset bottomInset:(CGFloat)bottomInset block:(void(^)())block {
    _nextY = 0.0;
    _controls = [[NSMutableArray alloc] init];
    _lastControlType = ControlTypeNone;
    _labelAdded = NO;

    block();

    CGFloat controlsHeight = -_nextY;
    CGFloat delta = bottomInset + controlsHeight;
    for (NSView *control in _controls) {
        NSRect frame = control.frame;
        frame.origin.y += delta;
        control.frame = frame;
    }

    NSRect frame = [_window contentRectForFrameRect:_window.frame];
    frame.size.height = controlsHeight + topInset + bottomInset;
    [_window setFrame:[_window frameRectForContentRect:frame] display:YES];

    [_controls release], _controls = nil;
}

- (NSPopUpButton *)addPopUpButton {
    NSPopUpButton *control = [[[NSPopUpButton alloc] initWithFrame:NSMakeRect(kPopUpControlX, 0, kPopUpControlWidth, kPopUpControlHeight) pullsDown:NO] autorelease];
    [self addControl:control ofType:ControlTypePopUp];
    return control;
}

- (NSButton *)addCheckboxWithTitle:(NSString *)title {
    NSButton *control = [[[NSButton alloc] initWithFrame:NSMakeRect(kCheckBoxX, 0, kCheckBoxWidth, kCheckBoxHeight)] autorelease];
    control.buttonType = NSSwitchButton;
    [control setTitle:title];
    [self addControl:control ofType:ControlTypeCheckBox];
    return control;
}

- (NSTextField *)addTextField {
    NSTextField *control = [[[NSTextField alloc] initWithFrame:NSMakeRect(kEditX, 0, kEditWidth, kEditHeight)] autorelease];
    [self addControl:control ofType:ControlTypeEdit];
    return control;
}

- (NSTextField *)addLabel:(NSString *)label {
    NSTextField *control = [[[NSTextField alloc] initWithFrame:NSMakeRect(kLabelX, _lastControlY + LAST.labelOffset, kLabelWidth, kLabelHeight)] autorelease];
    control.drawsBackground = control.selectable = control.editable = control.bezeled = NO;
    control.alignment = NSRightTextAlignment;
    control.stringValue = label;
    [_window.contentView addSubview:control];
    [_controls addObject:control];
    _labelAdded = YES;
    return control;
}

- (NSTextField *)addFullWidthLabel:(NSString *)label {
    NSTextField *control = [[[NSTextField alloc] initWithFrame:NSMakeRect(kLabelX, 0, kFullWidthLabelWidth, kLabelHeight)] autorelease];
    control.drawsBackground = control.selectable = control.editable = control.bezeled = NO;
    control.alignment = NSCenterTextAlignment;
    control.stringValue = label;
    [self addControl:control ofType:ControlTypeFullWidthLabel];
    _labelAdded = YES;
    return control;
}

- (NSTextField *)addRightLabel:(NSString *)label {
    NSTextField *control = [[[NSTextField alloc] initWithFrame:NSMakeRect(kRightLabelX, 0, kRightLabelWidth, kLabelHeight)] autorelease];
    control.drawsBackground = control.selectable = control.editable = control.bezeled = NO;
    control.alignment = NSLeftTextAlignment;
    control.stringValue = label;
    [self addControl:control ofType:ControlTypeRightLabel];
    return control;
}

- (void)addVisualBreak {
    _nextY -= 10;
}


#pragma mark - Internal methods

- (void)addControl:(NSView *)control ofType:(ControlType)type {
    [_window.contentView addSubview:control];
    [_controls addObject:control];

    NSRect frame = control.frame;
    frame.origin.y = _nextY - frame.size.height - LAST.bottomMargins[type];
    control.frame = frame;

    _lastControlType = type;
    _labelAdded = NO;
    _lastControlY = frame.origin.y;
    _nextY = NSMinY(control.frame);
}

@end
