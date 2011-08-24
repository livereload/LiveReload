
#import "ToolErrorWindowController.h"

#import "ToolError.h"
#import "Project.h"

#import "EditorManager.h"
#import "Editor.h"

#import "Compiler.h"


static ToolErrorWindowController *lastErrorController = nil;

@interface ToolErrorWindowController () <NSAnimationDelegate, NSTextViewDelegate>

+ (void)setLastErrorController:(ToolErrorWindowController *)controller;

@property (nonatomic, assign) enum UnparsedErrorState state;
@property (nonatomic, readonly) NSString *key;

- (void)hide:(BOOL)animated;
- (void)updateJumpToErrorEditor;

- (NSAttributedString *)prepareMessageForState:(enum UnparsedErrorState)state;
- (NSURL *)errorReportURL;
- (void)sendErrorReport;

@end

@implementation ToolErrorWindowController

@synthesize key = _key;
@synthesize state = _state;
@synthesize fileNameLabel = _fileNameLabel;
@synthesize lineNumberLabel = _lineNumberLabel;
@synthesize unparsedView = _unparsedView;
@synthesize messageView = _messageView;
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
    [_messageView setEditable:NO];
    [_messageView setDrawsBackground:NO];
    [_unparsedView setDelegate:self];

    _fileNameLabel.stringValue = [_compilerError.sourcePath lastPathComponent];

    CGFloat oldHeight = _messageView.frame.size.height;
    [_messageView setString:_compilerError.message];
    NSLayoutManager * lm = [_messageView layoutManager];
    NSTextContainer * tc = [_messageView textContainer];
    [lm glyphRangeForTextContainer:tc]; // forces layout manager to relayout container
    CGFloat heightDelta = _messageView.frame.size.height - oldHeight;

    if (_compilerError.raw) {
        _lineNumberLabel.textColor = [NSColor redColor];
        _lineNumberLabel.stringValue = @"Unparsed";
        self.state = UnparsedErrorStateDefault;
    } else {
        _lineNumberLabel.stringValue = (_compilerError.line ? [NSString stringWithFormat:@"%d", _compilerError.line] : @"");
        heightDelta -= _unparsedView.frame.size.height;
        [_unparsedView setHidden:YES];
    }

    NSRect windowFrame = self.window.frame;
    windowFrame.size.height += heightDelta;
    [self.window setFrame:windowFrame display:YES];

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

#pragma mark -

- (NSAttributedString *)prepareMessageForState:(enum UnparsedErrorState)state {
    NSString * message;
    NSMutableAttributedString * resultString;
    NSRange range;
    switch (state) {
        case UnparsedErrorStateDefault:
            message = @"LiveReload failed to parse this error message. Please submit the message to our server for analysis.";
            range = [message rangeOfString:@"submit the message"];
            resultString = [[[NSMutableAttributedString alloc] initWithString: message] autorelease];

            [resultString beginEditing];
            [resultString addAttribute:NSLinkAttributeName value:[[self errorReportURL] absoluteString] range:range];
            [resultString endEditing];
            break;

        case UnparsedErrorStateConnecting :
            message = @"Sending the error message to livereload.com…";
            resultString = [[[NSMutableAttributedString alloc] initWithString:message] autorelease];
            break;

        case UnparsedErrorStateFail :
            message = @"Failed to send the message to livereload.com. Retry";
            range = [message rangeOfString:@"Retry"];
            resultString = [[[NSMutableAttributedString alloc] initWithString: message] autorelease];

            [resultString beginEditing];
            [resultString addAttribute:NSLinkAttributeName value:[[self errorReportURL] absoluteString] range:range];
            [resultString endEditing];
            break;

        case UnparsedErrorStateSuccess :
            message = @"The error message has been sent for analysis. Thanks!";
            resultString = [[[NSMutableAttributedString alloc] initWithString:message] autorelease];
            break;

        default: return nil;
    }
    return resultString;
}

- (NSURL *)errorReportURL {
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *internalVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://livereload.com/api/submit-error-message.php?v=%@&iv=%@&compiler=%@",
                                 [version stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                 [internalVersion stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                 _compilerError.compiler.name]];
}

- (void)sendErrorReport {
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[self errorReportURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval: 60.0];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[_compilerError.message dataUsingEncoding:NSUTF8StringEncoding]];
    [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)setState:(enum UnparsedErrorState)state {
    _state = state;
    [[_unparsedView textStorage] setAttributedString:[self prepareMessageForState:state]];
}

#pragma mark -
#pragma mark NSTextViewDelegate
- (BOOL)textView:(NSTextView *)textView clickedOnLink:(id)link {
    if ( textView == _unparsedView ) {
        self.state = UnparsedErrorStateConnecting;
        [self sendErrorReport];
        return YES;
    }
    return NO;
}

#pragma mark -
#pragma mark NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.state = UnparsedErrorStateSuccess;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    self.state = UnparsedErrorStateFail;
}
@end
