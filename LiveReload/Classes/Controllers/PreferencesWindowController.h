
#import <Cocoa/Cocoa.h>


#define PreferencesDoneKey @"PreferencesDone"


@interface PreferencesWindowController : NSWindowController {
@private
    NSButton *_startAtLoginCheckbox;
    NSButton *_installSafariExtensionButton;
    NSButton *_installChromeExtensionButton;
    NSButton *_installFirefoxExtensionButton;
    NSTextField *_versionLabel;
    NSTextField *_webSiteLabel;
    NSButton *_backToMainWindowButton;
}

@property (assign) IBOutlet NSButton *startAtLoginCheckbox;
@property (assign) IBOutlet NSButton *installSafariExtensionButton;
@property (assign) IBOutlet NSButton *installChromeExtensionButton;
@property (assign) IBOutlet NSButton *installFirefoxExtensionButton;
@property (assign) IBOutlet NSTextField *versionLabel;
@property (assign) IBOutlet NSTextField *webSiteLabel;
@property (assign) IBOutlet NSButton *backToMainWindowButton;

- (void)willShow;

@end
