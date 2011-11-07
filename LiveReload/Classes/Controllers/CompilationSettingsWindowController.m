
#import "CompilationSettingsWindowController.h"

#import "PluginManager.h"
#import "Compiler.h"



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
#define kWindowTopMargin 118
#define kWindowBottomMargin 100



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


@implementation CompilationSettingsWindowController


#pragma mark - Actions

- (IBAction)showHelp:(id)sender {
    TenderShowArticle(@"features/compilation");
}


#pragma mark - UI Builder

- (void)buildUI:(void(^)())block {
    _nextY = 0.0;
    _controls = [NSMutableArray array];
    _lastControlType = ControlTypeNone;
    _labelAdded = NO;

    block();

    CGFloat controlsHeight = -_nextY;
    CGFloat delta = kWindowBottomMargin + controlsHeight;
    for (NSView *control in _controls) {
        NSRect frame = control.frame;
        frame.origin.y += delta;
        control.frame = frame;
    }

    NSRect frame = [self.window contentRectForFrameRect:self.window.frame];
    frame.size.height = controlsHeight + kWindowTopMargin + kWindowBottomMargin;
    [self.window setFrame:[self.window frameRectForContentRect:frame] display:YES];

    _controls = nil;
}

- (void)addControl:(NSView *)control ofType:(ControlType)type {
    [self.window.contentView addSubview:control];
    [_controls addObject:control];

    NSRect frame = control.frame;
    frame.origin.y = _nextY - frame.size.height - LAST.bottomMargins[type];
    control.frame = frame;

    _lastControlType = type;
    _labelAdded = NO;
    _lastControlY = frame.origin.y;
    _nextY = NSMinY(control.frame);
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
    [self.window.contentView addSubview:control];
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


#pragma mark - Compiler settings

- (void)renderCheckBoxOption:(NSDictionary *)option forCompiler:(Compiler *)compiler {
    NSString *title = [option objectForKey:@"Title"];
    [self addCheckboxWithTitle:title];
}

- (void)renderSelectOption:(NSDictionary *)option forCompiler:(Compiler *)compiler {
    NSArray *items = [option objectForKey:@"Items"];
    NSPopUpButton *popUp = [self addPopUpButton];
    [popUp addItemsWithTitles:[items valueForKeyPath:@"Title"]];
}

- (void)renderEditOption:(NSDictionary *)option forCompiler:(Compiler *)compiler {
    NSTextField *control = [self addTextField];

    NSString *placeholder = [option objectForKey:@"Placeholder"];
    if (placeholder.length > 0) {
        [control.cell setPlaceholderString:placeholder];
    }
}

- (void)renderSettingsForCompiler:(Compiler *)compiler isFirst:(BOOL *)isFirstCompiler {
    if (!*isFirstCompiler)
        [self addVisualBreak];
    *isFirstCompiler = NO;

    BOOL isFirst = YES;
    for (NSDictionary *option in compiler.options) {
        NSString *type = [option objectForKey:@"Type"];
        if ([type isEqualToString:@"checkbox"]) {
            [self renderCheckBoxOption:option forCompiler:compiler];
        } else if ([type isEqualToString:@"select"]) {
            [self renderSelectOption:option forCompiler:compiler];
        } else if ([type isEqualToString:@"edit"]) {
            [self renderEditOption:option forCompiler:compiler];
        } else {
            continue;
        }

        NSString *label = [option objectForKey:@"Label"];
        if ([label length] > 0) {
            [self addLabel:label];
        }

        if (isFirst && !_labelAdded) {
            [self addLabel:[NSString stringWithFormat:@"%@:", compiler.name]];
        }
        isFirst = NO;
    }

    if (isFirst) {
        [self addRightLabel:@"No options for this compiler"];
        [self addLabel:[NSString stringWithFormat:@"%@:", compiler.name]];
    }
}


#pragma mark - Model sync

- (void)render {
    NSArray *compilers = _project.compilersInUse;

    [self buildUI:^{
        if (compilers.count > 0) {
            BOOL isFirst = YES;
            for (Compiler *compiler in compilers) {
                [self renderSettingsForCompiler:compiler isFirst:&isFirst];
            }
        } else {
            [self addFullWidthLabel:@"No compilable files found in this folder."];
        }
    }];
}

- (void)save {
}


@end
