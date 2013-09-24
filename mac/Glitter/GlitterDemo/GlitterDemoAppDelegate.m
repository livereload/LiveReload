
#import "GlitterDemoAppDelegate.h"
#import "Glitter.h"

extern Glitter *sharedGlitter;


@interface GlitterDemoAppDelegate ()

@property (weak) IBOutlet NSButton *checkForUpdatesButton;
@property (weak) IBOutlet NSButton *installUpdateButton;
@property (weak) IBOutlet NSTextField *actionField;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;

@end


@implementation GlitterDemoAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.window.title = [NSString stringWithFormat:@"GlitterDemo %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];

    [sharedGlitter checkForUpdatesWithOptions:0];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateStatus) name:GlitterStatusDidChangeNotification object:sharedGlitter];
    [self updateStatus];
}

- (IBAction)checkForUpdates:(id)sender {
    [sharedGlitter checkForUpdatesWithOptions:GlitterCheckOptionUserInitiated];
}

- (IBAction)installUpdate:(id)sender {
    [sharedGlitter installUpdate];
}

- (void)updateStatus {
    if (sharedGlitter.checking && sharedGlitter.checkIsUserInitiated) {
        [_checkForUpdatesButton setTitle:@"Checking..."];
        [_checkForUpdatesButton setEnabled:NO];
    } else {
        [_checkForUpdatesButton setTitle:@"Check for Updates"];
        [_checkForUpdatesButton setEnabled:YES];
    }

    if (sharedGlitter.checking) {
        _actionField.stringValue = @"Checking for updates...";
        [_progressIndicator setHidden:NO];
        [_progressIndicator setIndeterminate:YES];
        [_progressIndicator startAnimation:nil];
    } else if (sharedGlitter.downloadStep == GlitterDownloadStepDownload) {
        _actionField.stringValue = [NSString stringWithFormat:@"Downloading v%@...", sharedGlitter.downloadingVersionDisplayName];
        [_progressIndicator setHidden:NO];
        [_progressIndicator setIndeterminate:NO];
        [_progressIndicator setMinValue:0];
        [_progressIndicator setMaxValue:100];
        [_progressIndicator setDoubleValue:sharedGlitter.downloadProgress];
    } else if (sharedGlitter.downloadStep == GlitterDownloadStepUnpack) {
        _actionField.stringValue = [NSString stringWithFormat:@"Unpacking v%@...", sharedGlitter.downloadingVersionDisplayName];
        [_progressIndicator setHidden:NO];
        [_progressIndicator setIndeterminate:YES];
        [_progressIndicator startAnimation:nil];
    } else {
        _actionField.stringValue = @"";
        [_progressIndicator setIndeterminate:NO];
        [_progressIndicator setHidden:YES];
    }

    if (sharedGlitter.readyToInstall) {
        [_installUpdateButton setTitle:[NSString stringWithFormat:@"Install v%@", sharedGlitter.readyToInstallVersionDisplayName]];
        [_installUpdateButton setEnabled:YES];
    } else {
        [_installUpdateButton setTitle:@"Install"];
        [_installUpdateButton setEnabled:NO];
    }
}

@end
