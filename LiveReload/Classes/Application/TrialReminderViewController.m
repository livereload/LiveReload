//
//  TrialReminderViewController.m
//  LiveReload
//
//  Created by Andrey Tarantsov on 2015-06-08.
//
//

#import "TrialReminderViewController.h"


@interface TrialReminderViewController ()

@property (nonatomic, strong) IBOutlet NSButton *buyOnMacAppStoreButton;
@property (nonatomic, strong) IBOutlet NSButton *negativeActionButton;
@property (nonatomic, strong) IBOutlet NSButton *expandButton;

@property (nonatomic, strong) IBOutlet NSTextField *importantMessageLabel;

@end

@implementation TrialReminderViewController {
//    CGFloat _normalHeight;
//    CGFloat _expandedHeight;
//    BOOL _expanded;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
//    _normalHeight = 270;
//    _expandedHeight = 450;
    NSMutableParagraphStyle *primaryParaStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    primaryParaStyle.paragraphSpacing = 8.0;

//    NSMutableParagraphStyle *authorParaStyle = [primaryParaStyle mutableCopy];
//    authorParaStyle.alignment = NSRightTextAlignment;
    
    NSString *primaryText = @"Hey!\n"
    @"I'm working on LiveReload in my spare time; if you love the app (and ONLY if you love the app!) please support me by purchasing it.\n";

    NSString *secondaryText = @"\nSo far, LiveReload has saved you 5,000 reloads. If each one only takes a second, that's 80 minutes of your time.\n";

    NSDictionary *primaryAttributes = @{NSFontAttributeName: [NSFont systemFontOfSize:[NSFont systemFontSize]], NSParagraphStyleAttributeName: primaryParaStyle};
//    NSDictionary *authorAttributes = @{NSFontAttributeName: [NSFont systemFontOfSize:[NSFont systemFontSize]], NSParagraphStyleAttributeName: authorParaStyle};
    NSDictionary *secondaryAttributes = @{NSFontAttributeName: [NSFont systemFontOfSize:[NSFont smallSystemFontSize]], NSParagraphStyleAttributeName: primaryParaStyle};
    
    NSMutableAttributedString *text = [NSMutableAttributedString new];
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:primaryText attributes:primaryAttributes]];
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:@"— Andrey Tarantsov.\n" attributes:primaryAttributes]];
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:secondaryText attributes:secondaryAttributes]];
    self.importantMessageLabel.attributedStringValue = text;
}

- (IBAction)buyOnMacAppStore:(id)sender {
    
}

- (IBAction)buyDirectly:(id)sender {
    
}

- (IBAction)later:(id)sender {
    
}

#if 0
- (IBAction)expand:(id)sender {
    // close the triangle animation transaction before starting the window animation
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!_expanded) {
            CGRect frame = self.window.frame;
            frame.size.height += (_expandedHeight - _normalHeight);
            frame.origin.y -= (_expandedHeight - _normalHeight);
            [self.window setFrame:frame display:YES animate:YES];
            _expanded = YES;
        } else {
            CGRect frame = self.window.frame;
            frame.size.height -= (_expandedHeight - _normalHeight);
            frame.origin.y += (_expandedHeight - _normalHeight);
            [self.window setFrame:frame display:YES animate:YES];
            _expanded = NO;
        }
    });
}
#endif

@end
