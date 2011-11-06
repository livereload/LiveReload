
#import <Cocoa/Cocoa.h>


@interface PreferencesWindowController : NSWindowController {
@private
    NSButton *_startAtLoginCheckbox;
    NSButton *_installSafariExtensionButton;
    NSButton *_installChromeExtensionButton;
    NSButton *_installFirefoxExtensionButton;
    NSTextField *_versionLabel;
    NSTextField *_webSiteLabel;
    NSButton *_backToMainWindowButton;
    NSTextField *_usingWithoutExtensionsLabel;
    NSTextField *_titleLabel;
    NSTextField *_installExtensionsHeaderLabel;
    NSTextField *_expiryLabel;
    NSTextField *_expiryDateLabel;
    NSTextField *_safariLabel;
    NSTextField *_chromeLabel;
}

@property (assign) IBOutlet NSButton *startAtLoginCheckbox;
@property (assign) IBOutlet NSButton *installSafariExtensionButton;
@property (assign) IBOutlet NSButton *installChromeExtensionButton;
@property (assign) IBOutlet NSButton *installFirefoxExtensionButton;
@property (assign) IBOutlet NSTextField *safariLabel;
@property (assign) IBOutlet NSTextField *chromeLabel;
@property (assign) IBOutlet NSTextField *versionLabel;
@property (assign) IBOutlet NSTextField *webSiteLabel;
@property (assign) IBOutlet NSButton *backToMainWindowButton;
@property (assign) IBOutlet NSTextField *usingWithoutExtensionsLabel;
@property (assign) IBOutlet NSTextField *titleLabel;
@property (assign) IBOutlet NSTextField *installExtensionsHeaderLabel;
@property (assign) IBOutlet NSTextField *expiryLabel;
@property (assign) IBOutlet NSTextField *expiryDateLabel;

- (void)willShow;

@end
