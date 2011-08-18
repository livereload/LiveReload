
#import "ToolErrorWindowController.h"

#import "ToolError.h"
#import "Project.h"

#import "EditorManager.h"
#import "Editor.h"


static ToolErrorWindowController *lastErrorController = nil;


@interface ToolErrorWindowController () <NSAnimationDelegate>

+ (void)setLastErrorController:(ToolErrorWindowController *)controller;

@property (nonatomic, readonly) NSString *key;

- (void)hide:(BOOL)animated;

- (void)updateJumpToErrorEditor;

@end



@implementation ToolErrorWindowController

@synthesize key=_key;
@synthesize fileNameLabel=_fileNameLabel;
@synthesize lineNumberLabel=_lineNumberLabel;
@synthesize messageView=_messageView;
@synthesize actionButton = _actionButton;
@synthesize jumpToErrorButton = _jumpToErrorButton;
@synthesize mailToServerButton = _mailToServerButton;


#pragma mark -

+ (void)setLastErrorController:(ToolErrorWindowController *)controller {
    if (lastErrorController != controller) {
        [lastErrorController release];
        lastErrorController = [controller retain];
    }
}

+ (void)hideErrorWindowWithKey:(NSString *)key {
    if ([lastErrorController.key isEqualToString:key]) {
        [lastErrorController hide:YES];
    }
}


#pragma mark -

- (id)initWithCompilerError:(ToolError *)compilerError key:(NSString *)key {
    self = [super initWithWindowNibName:@"ToolErrorWindowController"];
    if (self) {
        _compilerError = [compilerError retain];
        _key = [key copy];
    }
    return self;
}


#pragma mark -

- (void)windowDidLoad {
    [super windowDidLoad];

    self.window.level = NSFloatingWindowLevel;
//    [self.window setOpaque:NO];
//    self.window.backgroundColor = [NSColor colorWithCalibratedWhite:237.0/255 alpha:0.9];

    _fileNameLabel.stringValue = [_compilerError.sourcePath lastPathComponent];

    if (_compilerError.raw) {
        [_mailToServerButton setHidden:NO];
        _mailToServerButton.alphaValue = 0.7;

        _lineNumberLabel.textColor = [NSColor redColor];
        _lineNumberLabel.stringValue = @"Unparsed";
    } else {
        _lineNumberLabel.stringValue = (_compilerError.line ? [NSString stringWithFormat:@"%d", _compilerError.line] : @"");
    }

    [_messageView setEditable:NO];
    [_messageView setDrawsBackground:NO];


    CGFloat oldHeight = _messageView.frame.size.height;
    [_messageView setString:_compilerError.message];
    NSLayoutManager * lm = [_messageView layoutManager];
    NSTextContainer * tc = [_messageView textContainer];
    [lm glyphRangeForTextContainer:tc]; // forces layout manager to relayout container
    CGFloat heightDelta = _messageView.frame.size.height - oldHeight;

    if ( heightDelta > 0 ) {
        NSRect windowFrame = self.window.frame;
        windowFrame.size.height += heightDelta;
        [self.window setFrame:windowFrame display:YES];
    }

    // add the gears icon to the action button
    NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""] autorelease];
    NSImage *actionImage = [NSImage imageNamed:NSImageNameActionTemplate];
    [actionImage setSize:NSMakeSize(10,10)];
    [menuItem setImage:actionImage];
    [[_actionButton menu] insertItem:menuItem atIndex:0];

    [self updateJumpToErrorEditor];
}


#pragma mark -

- (NSDictionary *)slideInAnimation {
    NSScreen *primaryScreen = [[NSScreen screens] objectAtIndex:0];
    NSRect screen = primaryScreen.visibleFrame;

    NSRect frame = self.window.frame;
    frame.origin.x = screen.origin.x + screen.size.width - frame.size.width;
    frame.origin.y = screen.origin.y + screen.size.height;
    [self.window setFrame:frame display:YES];
    [self.window orderFrontRegardless];

    NSRect targetFrame = frame;
    targetFrame.origin.y -= frame.size.height;
    return [NSDictionary dictionaryWithObjectsAndKeys:self.window, NSViewAnimationTargetKey, [NSValue valueWithRect:targetFrame], NSViewAnimationEndFrameKey, nil];
}

- (NSDictionary *)slideOutAnimation {
    NSRect frame = self.window.frame;
    frame.origin.y -= frame.size.height;
    return [NSDictionary dictionaryWithObjectsAndKeys:self.window, NSViewAnimationTargetKey, [NSValue valueWithRect:frame], NSViewAnimationEndFrameKey, NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey, nil];
}

- (NSDictionary *)fadeOutAnimation {
    return [NSDictionary dictionaryWithObjectsAndKeys:self.window, NSViewAnimationTargetKey, NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey, nil];
}

- (void)show {
    if (lastErrorController) {
        _previousWindowController = [lastErrorController retain];
    }
    [ToolErrorWindowController setLastErrorController:self];

    NSArray *animations;
    if (_previousWindowController) {
        if (_previousWindowController->_appearing) {
            _previousWindowController->_suicidal = YES;
            animations = [NSArray arrayWithObject:[self slideInAnimation]];
        } else {
            animations = [NSArray arrayWithObjects:[self slideInAnimation], [_previousWindowController fadeOutAnimation], nil];
        }
    } else {
        animations = [NSArray arrayWithObject:[self slideInAnimation]];
    }
    NSViewAnimation *animation = [[[NSViewAnimation alloc] initWithViewAnimations:animations] autorelease];
    [animation setDelegate:self];
    [animation setDuration:0.25];
    [animation startAnimation];

    _appearing = YES;
    [self retain]; // will be released by animation delegate method
}

- (void)hide:(BOOL)animated {
    if (_appearing) {
        _suicidal = YES;
    } else {
        if (animated) {
            [self retain]; // will be released by animation delegate method

            NSViewAnimation *animation = [[[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:[self fadeOutAnimation]]] autorelease];
            [animation setDelegate:self];
            [animation setDuration:0.25];
            [animation startAnimation];
        } else {
            [self.window orderOut:nil];
        }
    }
    [ToolErrorWindowController setLastErrorController:nil];
}

- (void)animationDidEnd:(NSAnimation*)animation {
    if (_appearing) {
        _appearing = NO;
        if (_previousWindowController) {
            [_previousWindowController release], _previousWindowController = nil;
        }
        if (_suicidal) {
            [self.window orderOut:nil];
        }
    }
    [self autorelease];
}


#pragma mark -

- (void)updateJumpToErrorEditor {
    [_editor release], _editor = nil;
    _editor = [[[EditorManager sharedEditorManager] activeEditor] retain];
    if (_editor) {
        [_jumpToErrorButton setEnabled:YES];
        [_jumpToErrorButton setTitle:[NSString stringWithFormat:@"Edit in %@", _editor.name]];
    } else {
        [_jumpToErrorButton setEnabled:NO];
        [_jumpToErrorButton setTitle:@"Edit"];
    }

    CGFloat defaultWidth = 106;
    NSString *defaultText = @"Edit in TextMate";
    NSSize defaultSize = [defaultText sizeWithAttributes:[NSDictionary dictionaryWithObject:[_jumpToErrorButton font] forKey:NSFontAttributeName]];
    CGFloat padding = defaultWidth - defaultSize.width;

    NSSize size = [[_jumpToErrorButton title] sizeWithAttributes:[NSDictionary dictionaryWithObject:[_jumpToErrorButton font] forKey:NSFontAttributeName]];
    CGFloat width = size.width + padding;

    NSRect frame = [_jumpToErrorButton frame];
    CGFloat delta = width - frame.size.width;
    frame.size.width += delta;
    frame.origin.x -= delta;
    [_jumpToErrorButton setFrame:frame];
}

- (IBAction)jumpToError:(id)sender {
    [self updateJumpToErrorEditor];
    if (_editor == nil)
        return;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.05 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
        // TODO: check for success before hiding!
        if (![_editor jumpToFile:_compilerError.sourcePath line:_compilerError.line]) {
            NSLog(@"Failed to jump to the error position.");
        }
    });
    [self hide:NO];
}


#pragma mark -

- (IBAction)revealInFinder:(id)sender {
    NSString *root = nil;
    if ([_compilerError.project relativePathForPath:_compilerError.sourcePath]) {
        root = _compilerError.project.path;
    }
    [[NSWorkspace sharedWorkspace] selectFile:_compilerError.sourcePath inFileViewerRootedAtPath:root];
}

- (IBAction)ignore:(id)sender {
    [self hide:NO];
}


@end
