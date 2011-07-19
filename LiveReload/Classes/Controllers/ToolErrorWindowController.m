
#import "ToolErrorWindowController.h"

#import "ToolError.h"
#import "Project.h"


static ToolErrorWindowController *lastErrorController = nil;


@interface ToolErrorWindowController () <NSAnimationDelegate>

+ (void)setLastErrorController:(ToolErrorWindowController *)controller;

@property (nonatomic, readonly) NSString *key;

- (void)hide:(BOOL)animated;

@end



@implementation ToolErrorWindowController

@synthesize key=_key;
@synthesize fileNameLabel=_fileNameLabel;
@synthesize lineNumberLabel=_lineNumberLabel;
@synthesize messageLabel=_messageLabel;
@synthesize actionButton = _actionButton;
@synthesize jumpToErrorButton = _jumpToErrorButton;


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
    _lineNumberLabel.stringValue = (_compilerError.line ? [NSString stringWithFormat:@"%d", _compilerError.line] : @"");
    _messageLabel.stringValue = _compilerError.message;

    // resize

    CGFloat oldHeight = _messageLabel.frame.size.height;
    [_messageLabel sizeToFit];
    CGFloat heightDelta = _messageLabel.frame.size.height - oldHeight;

    NSRect messageFrame = _messageLabel.frame;
    messageFrame.origin.y -= heightDelta;
    _messageLabel.frame = messageFrame;

    NSRect windowFrame = self.window.frame;
    windowFrame.size.height += heightDelta;
    [self.window setFrame:windowFrame display:YES];

    // add the gears icon to the action button
    NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""] autorelease];
    NSImage *actionImage = [NSImage imageNamed:NSImageNameActionTemplate];
    [actionImage setSize:NSMakeSize(10,10)];
    [menuItem setImage:actionImage];
    [[_actionButton menu] insertItem:menuItem atIndex:0];
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

- (IBAction)jumpToError:(id)sender {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.05 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
        NSString *url = [NSString stringWithFormat:@"txmt://open/?url=file://%@&line=%d", [_compilerError.sourcePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], _compilerError.line];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
    });
    [self hide:NO];
}

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
