
@interface DemoAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *_window;
    NSWindowController *_preferencesWindowController;
}

@property (nonatomic, assign) IBOutlet NSWindow *window;
@property (nonatomic, readonly) NSWindowController *preferencesWindowController;

@property (nonatomic) NSInteger focusedAdvancedControlIndex;

- (IBAction)openPreferences:(id)sender;

@end
