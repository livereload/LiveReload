
#import "AddCustomRubySheet.h"
#import "ATSandboxing.h"
#import "RubyRuntimes.h"

typedef enum {
    ProgressStatusNone,
    ProgressStatusInProgress,
    ProgressStatusSucceeded,
    ProgressStatusFailed,
} ProgressStatus;

@interface AddCustomRubySheet ()

@property (assign) IBOutlet NSMatrix *typeMatrix;

@property (assign) IBOutlet NSButton *chooseDirectoryButton;
@property (assign) IBOutlet NSTextField *directoryExplanationField;
@property (assign) IBOutlet NSTextField *chosenDirectoryField;

@property (assign) IBOutlet NSProgressIndicator *progressIndicator;
@property (assign) IBOutlet NSTextField *progressMessage;

@property (assign) IBOutlet NSButton *addButton;

@property(nonatomic, strong) NSURL *chosenURL;
@property(nonatomic, assign) BOOL valid;

@end

@implementation AddCustomRubySheet {
    NSArray *_typeChoices;
}

- (id)init {
    self = [super initWithWindowNibName:NSStringFromClass([self class])];
    if (self) {
        _typeChoices = [@[
            @{
                @"name": @"RVM",
                @"hint": @"Choose your RVM installation root folder (typically ~/.rvm) to give LiveReload access to all RVM rubies.",
                @"okButton": @"Add Rubies",
                @"openTitle": @"Add RVM Installation",
                @"openMessage": @"Confirm the root folder of the RVM installation",
                @"openButton": @"Add RVM",
                @"defaultDir": @"~/.rvm",
                @"klass": [RvmContainer class],
            },
            @{
                @"name": @"rbenv",
                @"hint": @"Choose your rbenv installation folder (typically ~/.rbenv) to give LiveReload access to all rbenv rubies.",
                @"okButton": @"Add Rubies",
                @"openTitle": @"Add rbenv installation",
                @"openMessage": @"Confirm the root folder of your rbenv installation",
                @"openButton": @"Add rbenv",
                @"defaultDir": @"~/.rbenv",
                @"klass": [RvmContainer class],
            },
            @{
                @"name": @"Homebrew",
                @"hint": @"Choose your Homebrew Ruby folder (typically /usr/local/Cellar/ruby) to give LiveReload access to all brewed rubies.",
                @"okButton": @"Add Rubies",
                @"openTitle": @"Add Homebrew Rubies",
                @"openMessage": @"Confirm the Homebrew Ruby folder",
                @"openButton": @"Add Homebrew Rubies",
                @"defaultDir": @"/usr/local/Cellar/ruby",
                @"klass": [RvmContainer class],
            },
            @{
                @"name": @"Custom Directory",
                @"hint": @"Choose the root folder of your Ruby installation. It should contain subfolders like bin and lib.",
                @"okButton": @"Add Ruby",
                @"openTitle": @"Add Custom Ruby Installation",
                @"openMessage": @"Choose the root folder of the Ruby installation",
                @"openButton": @"Add Ruby",
                @"defaultDir": @"",
                @"klass": [RvmContainer class],
            },
            @{
                @"name": @"Custom Prefix",
                @"hint": @"Choose the prefix folder that contains your Ruby installation — e.g. /usr, /usr/local, /opt/local.",
                @"okButton": @"Add Ruby",
                @"openTitle": @"Add Custom Ruby Prefix Folder",
                @"openMessage": @"Choose the prefix folder that contains your Ruby installation",
                @"openButton": @"Add Ruby",
                @"defaultDir": @"/usr/local",
                @"klass": [RvmContainer class],
            },
        ] retain];
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self setProgressStatus:ProgressStatusNone message:@""];
    [self render];
}

- (NSDictionary *)selectedTypeInfo {
    return _typeChoices[(int)_typeMatrix.selectedTag];
}

- (IBAction)chooseFolder:(id)sender {
    NSDictionary *typeInfo = self.selectedTypeInfo;

    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanCreateDirectories:NO];
    [openPanel setTitle:typeInfo[@"openTitle"]];
    [openPanel setMessage:typeInfo[@"openMessage"]];
    [openPanel setPrompt:typeInfo[@"openButton"]];
    [openPanel setCanChooseFiles:NO];
    [openPanel setTreatsFilePackagesAsDirectories:YES];

    NSString *defaultDir = typeInfo[@"defaultDir"];
    if ([defaultDir length] > 0) {
        defaultDir = [defaultDir stringByExpandingTildeInPathUsingRealHomeDirectory];
        [openPanel setDirectoryURL:[NSURL fileURLWithPath:defaultDir]];
    }

    NSInteger result = [openPanel runModal];
    if (result == NSFileHandlingPanelOKButton) {
        NSURL *url = [openPanel URL];
        self.chosenURL = url;
        self.valid = NO;
        [self render];

        [self setProgressStatus:ProgressStatusInProgress message:@"Validating..."];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1500 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            self.valid = YES;
            [self setProgressStatus:ProgressStatusSucceeded message:@"Ruby v1.8.7"];
            [self render];
        });

    }
}

- (IBAction)typeModified:(id)sender {
    [self render];
}

- (void)setProgressStatus:(ProgressStatus)status message:(NSString *)message {
    if (status == ProgressStatusInProgress)
        [self.progressIndicator startAnimation:self];
    else
        [self.progressIndicator stopAnimation:self];

    if (status == ProgressStatusSucceeded) {
        message = [NSString stringWithFormat:@"✓ %@", message];
    }

    self.progressMessage.stringValue = message;
}

- (void)render {
    self.chosenDirectoryField.stringValue = [self.chosenURL path] ?: @"";
    self.addButton.enabled = self.valid;

    NSDictionary *typeInfo = self.selectedTypeInfo;
    self.directoryExplanationField.stringValue = typeInfo[@"hint"];
    self.addButton.title = typeInfo[@"okButton"];
}

- (IBAction)addClicked:(id)sender {
    [NSApp endSheet:self.window];
}

- (IBAction)helpClicked:(id)sender {
}

@end
