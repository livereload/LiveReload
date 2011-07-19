
#import "PreferencesWindowController.h"
#import "ExtensionsController.h"

#import "NSWindowController+TextStyling.h"



@interface PreferencesWindowController ()
@end



@implementation PreferencesWindowController

@synthesize startAtLoginCheckbox = _startAtLoginCheckbox;
@synthesize installSafariExtensionButton = _installSafariExtensionButton;
@synthesize installChromeExtensionButton = _installChromeExtensionButton;
@synthesize installFirefoxExtensionButton = _installFirefoxExtensionButton;
@synthesize versionLabel = _versionLabel;
@synthesize webSiteLabel = _webSiteLabel;
@synthesize backToMainWindowButton = _backToMainWindowButton;
@synthesize usingWithoutExtensionsLabel = _usingWithoutExtensionsLabel;
@synthesize titleLabel = _titleLabel;
@synthesize installExtensionsHeaderLabel = _installExtensionsHeaderLabel;
@synthesize expiryLabel = _expiryLabel;
@synthesize expiryDateLabel = _expiryDateLabel;
@synthesize safariLabel = _safariLabel;
@synthesize chromeLabel = _chromeLabel;


#pragma mark -

- (id)init {
    self = [super initWithWindowNibName:@"PreferencesWindowController"];
    if (self) {
        // Initialization code here.
    }

    return self;
}

- (void)dealloc {
    [super dealloc];
}


#pragma mark -

- (void)windowDidLoad {
    [super windowDidLoad];
    [self.window setLevel:NSFloatingWindowLevel];
    [self.window setStyleMask:NSBorderlessWindowMask];
    [self.window setOpaque:NO];
    [self.window setBackgroundColor:[NSColor clearColor]];

    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    [self.versionLabel setStringValue:[NSString stringWithFormat:@"v%@", version]];

    NSShadow *shadow = [self subtleWhiteShadow];
    NSColor *color = [NSColor colorWithCalibratedRed:63.0/255 green:70.0/255 blue:98.0/255 alpha:1.0];
    NSColor *linkColor = [NSColor colorWithCalibratedRed:109.0/255 green:118.0/255 blue:149.0/255 alpha:1.0];

    [self styleButton:_startAtLoginCheckbox color:color shadow:shadow];
    [self styleLabel:_titleLabel color:color shadow:shadow];
    [self styleLabel:_versionLabel color:color shadow:shadow];
    [self styleLabel:_expiryLabel color:color shadow:shadow];
    [self styleLabel:_expiryDateLabel color:color shadow:shadow];
    [self styleLabel:_installExtensionsHeaderLabel color:color shadow:shadow];
    [self styleLabel:_safariLabel color:color shadow:shadow];
    [self styleLabel:_chromeLabel color:color shadow:shadow];
    [self styleHyperlink:self.webSiteLabel color:linkColor shadow:shadow];
    [self styleHyperlink:self.usingWithoutExtensionsLabel to:[NSURL URLWithString:@"http://help.livereload.com/kb/general-use/using-livereload-without-browser-extensions"] color:linkColor shadow:shadow];
}

- (void)willShow {
    ExtensionsController *extensionsController = [ExtensionsController sharedExtensionsController];

    NSInteger safariVersion = extensionsController.versionOfInstalledSafariExtension;
    if (safariVersion == 0) {
        [self.installSafariExtensionButton setTitle:@"Install"];
        [self.installSafariExtensionButton setEnabled:YES];
    } else if (safariVersion < extensionsController.latestSafariExtensionVersion) {
        [self.installSafariExtensionButton setTitle:@"Update"];
        [self.installSafariExtensionButton setEnabled:YES];
    } else {
        [self.installSafariExtensionButton setTitle:@"Installed"];
        [self.installSafariExtensionButton setEnabled:NO];
    }

    NSInteger chromeVersion = extensionsController.versionOfInstalledChromeExtension;
    if (chromeVersion == 0) {
        [self.installChromeExtensionButton setTitle:@"Install"];
        [self.installChromeExtensionButton setEnabled:YES];
    } else if (chromeVersion < extensionsController.latestChromeExtensionVersion) {
        [self.installChromeExtensionButton setTitle:@"Update"];
        [self.installChromeExtensionButton setEnabled:YES];
    } else {
        [self.installChromeExtensionButton setTitle:@"Installed"];
        [self.installChromeExtensionButton setEnabled:NO];
    }

    [self.backToMainWindowButton setTitle:([[NSUserDefaults standardUserDefaults] boolForKey:PreferencesDoneKey] ? @"Apply" : @"Continue")];
}

@end
