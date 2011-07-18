
#import "PreferencesWindowController.h"
#import "ExtensionsController.h"



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

    // both are needed, otherwise hyperlink won't accept mousedown
    [self.webSiteLabel setAllowsEditingTextAttributes:YES];
    [self.webSiteLabel setSelectable:YES];

    [self.webSiteLabel setAttributedStringValue:[[[NSAttributedString alloc] initWithString:[self.webSiteLabel stringValue] attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor blueColor], NSForegroundColorAttributeName, [NSNumber numberWithInt:NSSingleUnderlineStyle], NSUnderlineStyleAttributeName, [NSURL URLWithString:[self.webSiteLabel stringValue]], NSLinkAttributeName, [NSFont systemFontOfSize:13], NSFontAttributeName, nil]] autorelease]];
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

    [self.backToMainWindowButton setTitle:([[NSUserDefaults standardUserDefaults] boolForKey:PreferencesDoneKey] ? @"Back to LiveReload" : @"Start using LiveReload")];
}

@end
