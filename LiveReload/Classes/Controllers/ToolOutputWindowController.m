
#import "ToolOutputWindowController.h"

#import "ToolOutput.h"
#import "Project.h"

#import "EditorManager.h"
#import "Editor.h"

#import "Compiler.h"


static ToolOutputWindowController *lastOutputController = nil;

@interface ToolOutputWindowController () <NSAnimationDelegate, NSTextViewDelegate>

+ (void)setLastOutputController:(ToolOutputWindowController *)controller;

@property (nonatomic, assign) enum UnparsedErrorState state;
@property (nonatomic, readonly) NSString *key;

- (void)loadMessageForOutputType:(enum ToolOutputType)type;
- (void)hideUnparsedNotificationView;

- (void)hide:(BOOL)animated;
- (void)updateJumpToErrorEditor;

- (NSAttributedString *)prepareSpecialMessage:(NSString *)message url:(NSURL *)url;
- (NSAttributedString *)prepareMessageForState:(enum UnparsedErrorState)state;
- (NSURL *)errorReportURL;
- (void)sendErrorReport;

@end

@implementation ToolOutputWindowController

@synthesize key = _key;
@synthesize state = _state;
@synthesize fileNameLabel = _fileNameLabel;
@synthesize lineNumberLabel = _lineNumberLabel;
@synthesize unparsedNotificationView = _unparsedNotificationView;
@synthesize messageView = _messageView;
@synthesize messageScroller = _messageScroller;
@synthesize actionButton = _actionButton;
@synthesize jumpToErrorButton = _jumpToErrorButton;
@synthesize showOutputMenuItem = _showOutputMenuItem;

#pragma mark -

+ (void)setLastOutputController:(ToolOutputWindowController *)controller {
    if (lastOutputController != controller) {
        [lastOutputController release];
        lastOutputController = [controller retain];
    }
}

+ (void)hideOutputWindowWithKey:(NSString *)key {
    if ([lastOutputController.key isEqualToString:key]) {
        [lastOutputController hide:YES];
    }
}


#pragma mark -

- (id)initWithCompilerOutput:(ToolOutput *)compilerOutput key:(NSString *)key {
    self = [super initWithWindowNibName:@"ToolOutputWindowController"];
    if (self) {
        _compilerOutput = [compilerOutput retain];
        _key = [key copy];
    }
    return self;
}

- (void)dealloc {
    [_compilerOutput release], _compilerOutput = nil;
    [_editor release], _editor = nil;
    [super dealloc];
}

#pragma mark -

- (void)windowDidLoad {
    [super windowDidLoad];

    self.window.level = NSFloatingWindowLevel;
    [_unparsedNotificationView setEditable:NO];
    [_unparsedNotificationView setDrawsBackground:NO];
    [_unparsedNotificationView setDelegate:self];

    [_messageScroller setBorderType:NSNoBorder];
    [_messageScroller setDrawsBackground:NO];


    [self loadMessageForOutputType:_compilerOutput.type];

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
    if (lastOutputController) {
        _previousWindowController = [lastOutputController retain];
    }
    [ToolOutputWindowController setLastOutputController:self];

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
    [ToolOutputWindowController setLastOutputController:nil];
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
- (void)loadMessageForOutputType:(enum ToolOutputType)type {
    if ([_compilerOutput.output rangeOfString:@"Nothing to compile. If you're trying to start a new project, you have left off the directory argument"].location != NSNotFound) {
        NSString *message = @"LiveReload knowledge base _[has an article about this error]_.";
        NSURL *url = [NSURL URLWithString:@"http://help.livereload.com/kb/troubleshooting/compass-nothing-to-compile"];
        [_unparsedNotificationView textStorage].attributedString = [self prepareSpecialMessage:message url:url];

        if (type == ToolOutputTypeErrorRaw)
            type = ToolOutputTypeError;
        _specialMessageURL = [url retain];
    } else if (type != ToolOutputTypeErrorRaw) {
        [self hideUnparsedNotificationView];
    }

    CGFloat maxHeight = [[[self window] screen] frame].size.height / 2;
    CGFloat oldHeight = _messageScroller.frame.size.height;

    switch (type) {
        case ToolOutputTypeLog :
            [_messageView setString:_compilerOutput.output];
            _lineNumberLabel.textColor = [NSColor blackColor];
            _lineNumberLabel.stringValue = (_compilerOutput.line ? [NSString stringWithFormat:@"%d", _compilerOutput.line] : @"");
            break;
        case ToolOutputTypeError :
            [_messageView setString:_compilerOutput.message];
            _lineNumberLabel.textColor = [NSColor blackColor];
            _lineNumberLabel.stringValue = (_compilerOutput.line ? [NSString stringWithFormat:@"%d", _compilerOutput.line] : @"");
            break;
        case ToolOutputTypeErrorRaw :
            [_messageView setString:_compilerOutput.message];
            _lineNumberLabel.textColor = [NSColor redColor];
            _lineNumberLabel.stringValue = @"Unparsed";
            self.state = UnparsedErrorStateDefault;
            break;
    }

    _fileNameLabel.stringValue = [_compilerOutput.sourcePath lastPathComponent] ?: @"";

    [[_messageView layoutManager] glyphRangeForTextContainer:[_messageView textContainer]]; // forces layout manager to relayout container
    CGFloat windowHeightDelta = _messageView.frame.size.height - oldHeight;

    NSRect windowFrame = self.window.frame;
    CGFloat finalDelta = MIN(windowFrame.size.height + windowHeightDelta, maxHeight) - windowFrame.size.height;
    windowFrame.size.height += finalDelta;
    windowFrame.origin.y -= finalDelta;
    [self.window setFrame:windowFrame display:YES];
}

- (void)hideUnparsedNotificationView {
    if ([_unparsedNotificationView isHidden] == NO ) {
        CGFloat scrollerHeightDelta = _unparsedNotificationView.frame.size.height + 10;

        NSUInteger mask = self.messageScroller.autoresizingMask;
        self.messageScroller.autoresizingMask = NSViewNotSizable;

        NSRect scrollerFrame = self.messageScroller.frame;
        scrollerFrame.size.height += scrollerHeightDelta;
        scrollerFrame.origin.y -= scrollerHeightDelta;
        self.messageScroller.frame = scrollerFrame;

        [_unparsedNotificationView setHidden:YES];
        self.messageScroller.autoresizingMask = mask;
    }
}

#pragma mark -

- (IBAction)showCompilationLog:(id)sender {
    [self.showOutputMenuItem setEnabled:NO];
    [self loadMessageForOutputType:ToolOutputTypeLog];
}

#pragma mark -

- (void)updateJumpToErrorEditor {
    [_editor release], _editor = nil;
    CGFloat defaultWidth = _jumpToErrorButton.frame.size.width;
    NSString *defaultText = _jumpToErrorButton.title;

    _editor = [[[EditorManager sharedEditorManager] activeEditor] retain];
    if (_editor) {
        [_jumpToErrorButton setEnabled:YES];
        [_jumpToErrorButton setTitle:[NSString stringWithFormat:@"Edit in %@", _editor.name]];
    } else {
        [_jumpToErrorButton setEnabled:NO];
        [_jumpToErrorButton setTitle:@"Edit"];
    }

    NSSize defaultSize = [defaultText sizeWithAttributes:[NSDictionary dictionaryWithObject:[_jumpToErrorButton font] forKey:NSFontAttributeName]];
    CGFloat padding = defaultWidth - defaultSize.width;

    NSSize size = [[_jumpToErrorButton title] sizeWithAttributes:[NSDictionary dictionaryWithObject:[_jumpToErrorButton font] forKey:NSFontAttributeName]];
    CGFloat width = ceil(size.width + padding);

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
        if (![_editor jumpToFile:_compilerOutput.sourcePath line:_compilerOutput.line]) {
            NSLog(@"Failed to jump to the error position.");
        }
    });
    [self hide:NO];
}


#pragma mark -

- (IBAction)revealInFinder:(id)sender {
    NSString *root = nil;
    if ([_compilerOutput.project isPathInsideProject:_compilerOutput.sourcePath]) {
        root = _compilerOutput.project.path;
    }
    [[NSWorkspace sharedWorkspace] selectFile:_compilerOutput.sourcePath inFileViewerRootedAtPath:root];
}

- (IBAction)ignore:(id)sender {
    [self hide:NO];
}

#pragma mark -

- (NSAttributedString *)prepareSpecialMessage:(NSString *)message url:(NSURL *)url {
    NSString *string = message;
    NSRange range = [string rangeOfString:@"_["];
    NSAssert(range.length > 0, @"Partial hyperlink must contain _[ marker");
    NSString *prefix = [string substringToIndex:range.location];
    string = [string substringFromIndex:range.location + range.length];

    range = [string rangeOfString:@"]_"];
    NSAssert(range.length > 0, @"Partial hyperlink must contain ]_ marker");
    NSString *link = [string substringToIndex:range.location];
    NSString *suffix = [string substringFromIndex:range.location + range.length];

    NSMutableAttributedString *as = [[[NSMutableAttributedString alloc] init] autorelease];

    [as appendAttributedString:[[[NSAttributedString alloc] initWithString:prefix] autorelease]];

    [as appendAttributedString:[[[NSAttributedString alloc] initWithString:link attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:NSSingleUnderlineStyle], NSUnderlineStyleAttributeName, url, NSLinkAttributeName, nil]] autorelease]];

    [as appendAttributedString:[[[NSAttributedString alloc] initWithString:suffix] autorelease]];

    return as;
}

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
                                 _compilerOutput.compiler.name]];
}

- (void)sendErrorReport {
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[self errorReportURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval: 60.0];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[_compilerOutput.output dataUsingEncoding:NSUTF8StringEncoding]];
    [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)setState:(enum UnparsedErrorState)state {
    _state = state;
    [[_unparsedNotificationView textStorage] setAttributedString:[self prepareMessageForState:state]];
}

#pragma mark -
#pragma mark NSTextViewDelegate
- (BOOL)textView:(NSTextView *)textView clickedOnLink:(id)link {
    if (_specialMessageURL)
        return NO;
    if ( textView == _unparsedNotificationView ) {
        self.state = UnparsedErrorStateConnecting;
        [self sendErrorReport];
        return YES;
    }
    return NO;
}

#pragma mark -
#pragma mark NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    _submissionResponseBody = [[NSMutableData alloc] init];
    _submissionResponseCode = httpResponse.statusCode;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_submissionResponseBody appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSString *responseString = [[[NSString alloc] initWithData:_submissionResponseBody encoding:NSUTF8StringEncoding] autorelease];
    if (_submissionResponseCode == 200 && [responseString isEqualToString:@"OK."]) {
        NSLog(@"Unparsable log submittion succeeded!");
        self.state = UnparsedErrorStateSuccess;
    } else {
        NSLog(@"Unparsable log submission failed with HTTP response code %ld, body:\n%@", (long)_submissionResponseCode, responseString);
        self.state = UnparsedErrorStateFail;
    }
    [_submissionResponseBody release], _submissionResponseBody = nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    self.state = UnparsedErrorStateFail;
    NSLog(@"Unparsable log submission failed with error: %@", [error localizedDescription]);
    [_submissionResponseBody release], _submissionResponseBody = nil;
}

@end
