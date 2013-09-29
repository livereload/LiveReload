
#import "GlitterUpdateInfoViewController.h"
#import "Glitter.h"


@interface GlitterUpdateInfoViewController ()
@end


@implementation GlitterUpdateInfoViewController {
    NSTextField *introLabel;
    NSButton *installButton;
//    NSTextField *whatsNewLabel;
    NSTextView *whatsNewLabel;
}

- (id)initWithGlitter:(Glitter *)glitter {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _glitter = glitter;
    }
    return self;
}

- (NSString *)formatCombinedNews:(NSArray *)combinedNews {
    NSMutableArray *htmlLines = [NSMutableArray new];

    [htmlLines addObject:@"<style>"];
    [htmlLines addObject:@"html, body, p, h2 { font: 13px Lucida Grande; margin: 0; padding: 0 }"];
    [htmlLines addObject:@"h2, p { margin-bottom: 0.5em; }"];
    [htmlLines addObject:@"h2 { font-weight: bold; }"];
    [htmlLines addObject:@"</style>"];

    BOOL first = YES;
    for (NSDictionary *versionNews in combinedNews) {
        if (first)
            first = NO;
        else
            [htmlLines addObject:@"<br>"]; // margin-top does not seem to work
        [htmlLines addObject:@"<article class=\"version\">"];
        [htmlLines addObject:[NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"Glitter.WhatsNewHtml.VersionHeaderFmt", nil, [NSBundle mainBundle], @"<h2>v%@</h2>", @""), versionNews[GlitterCombinedNewsVersionDisplayNameKey]]];
        [htmlLines addObject:[NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"Glitter.WhatsNewHtml.VersionDataFmt", nil, [NSBundle mainBundle], @"%@", @""), versionNews[GlitterCombinedNewsVersionNewsKey]]];
        [htmlLines addObject:@"</article>"];
    }
    return [htmlLines componentsJoinedByString:@"\n"];
}

- (void)loadView {
    NSDictionary *metrics = @{@"hpad": @16.0, @"vpad": @12.0, @"vspace": @12.0};
    CGFloat textWidth = 350.0;
    CGFloat maxAllowedTextHeight = 300.0;

    self.view = [[NSView alloc] init];

    introLabel = [self staticLabelWithString:NSLocalizedStringWithDefaultValue(@"Glitter.UpdateInfo.IntroLabel", nil, [NSBundle mainBundle], @"Update is ready to be installed!", @"")];
    [introLabel setContentHuggingPriority:1 forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self.view addSubview:introLabel];

    NSString *installButtonTitle = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"Glitter.UpdateInfo.InstallButton.LabelFmt", nil, [NSBundle mainBundle], @"Relaunch", @""), _glitter.readyToInstallVersionDisplayName];
    installButton = [self buttonWithTitle:installButtonTitle type:NSMomentaryPushInButton bezelStyle:NSTexturedRoundedBezelStyle];
    installButton.target = self;
    installButton.action = @selector(installClicked:);
    [self.view addSubview:installButton];

    NSString *html = [self formatCombinedNews:_glitter.readyToInstallCombinedNews];
    NSLog(@"html:\n%@\n", html);
    NSData *htmlData = [html dataUsingEncoding:NSUTF8StringEncoding];
    NSAttributedString *as = [[NSAttributedString alloc] initWithHTML:htmlData options:@{NSCharacterEncodingDocumentOption: @(NSUTF8StringEncoding)} documentAttributes:NULL];

//    whatsNewLabel = [self staticLabelWithAttributedString:as];
//    [whatsNewLabel setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationVertical];
//    [self.view addSubview:whatsNewLabel];

    CGSize textSize = [as boundingRectWithSize:CGSizeMake(textWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading].size;
    textSize.width = textWidth;

    whatsNewLabel = [[NSTextView alloc] initWithFrame:CGRectZero];
    whatsNewLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [whatsNewLabel setEditable:YES];
    [whatsNewLabel insertText:as];
    [whatsNewLabel setEditable:NO];
    [whatsNewLabel setHorizontallyResizable:NO];
    [whatsNewLabel setVerticallyResizable:YES];
    [whatsNewLabel setDrawsBackground:NO];
    [whatsNewLabel setTextContainerInset:CGSizeZero]; // does not seem to be required, but just in case
    [[whatsNewLabel textContainer] setLineFragmentPadding:0.0]; // definitely required to get rid of the default margin
    [[whatsNewLabel textContainer] setContainerSize:CGSizeMake(textSize.width, CGFLOAT_MAX)];
    [[whatsNewLabel textContainer] setWidthTracksTextView:YES];

    NSView *whatsNewView;
    if (textSize.height > maxAllowedTextHeight) {
        NSScrollView *whatsNewScrollView = [[NSScrollView alloc] initWithFrame:CGRectZero];
        whatsNewScrollView.translatesAutoresizingMaskIntoConstraints = NO;
        [whatsNewScrollView setBorderType:NSNoBorder];
        [whatsNewScrollView setHasVerticalScroller:YES];
        [whatsNewScrollView setHasHorizontalScroller:NO];
        [whatsNewScrollView setDrawsBackground:NO];
        [whatsNewScrollView setDocumentView:whatsNewLabel];
        [self.view addSubview:whatsNewScrollView];

        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:whatsNewScrollView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:textSize.width]];
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:whatsNewScrollView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:maxAllowedTextHeight]];
        whatsNewView = whatsNewScrollView;
    } else {
        [self.view addSubview:whatsNewLabel];
        whatsNewView = whatsNewLabel;
    }

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:whatsNewLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:textSize.width]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:whatsNewLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:textSize.height]];

    NSDictionary *bindings = NSDictionaryOfVariableBindings(introLabel, whatsNewLabel, whatsNewView, installButton);

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-hpad-[whatsNewView]-hpad-|" options:0 metrics:metrics views:bindings]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-hpad-[introLabel]-(>=50)-[installButton]-hpad-|" options:NSLayoutFormatAlignAllBaseline metrics:metrics views:bindings]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-vpad-[installButton]-vspace-[whatsNewView]|" options:0 metrics:metrics views:bindings]];

    // without this call, the popover animates from what seems like a zero size
    [self.view layoutSubtreeIfNeeded];
}

- (IBAction)installClicked:(id)sender {
    [_glitter installUpdate];
}

- (NSButton *)buttonWithTitle:(NSString *)title type:(NSButtonType)type bezelStyle:(NSBezelStyle)bezelStyle {
    NSButton *view = [[NSButton alloc] initWithFrame:CGRectZero];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [view setButtonType:type];
    [view setBezelStyle:bezelStyle];
    if (bezelStyle == NSRecessedBezelStyle) {
        // Interface Builder sets it up this way automatically
        [view setShowsBorderOnlyWhileMouseInside:YES];
    }
    [view setTitle:title];
    return view;
}

- (NSTextField *)staticLabelWithString:(NSString *)text {
    NSTextField *view = [[NSTextField alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [view setBordered:NO];
    [view setEditable:NO];
    [view setDrawsBackground:NO];
    [view setStringValue:text];
    return view;
}

- (NSTextField *)staticLabelWithAttributedString:(NSAttributedString *)text {
    NSTextField *view = [[NSTextField alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [view setBordered:NO];
    [view setEditable:NO];
    [view setDrawsBackground:NO];
    [view setAttributedStringValue:text];
    return view;
}

@end
