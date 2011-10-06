
@interface DemoAppDelegate : NSObject <NSApplicationDelegate>
{
@private
    
    NSWindow *_window;
    NSWindowController *_preferencesWindowController;
}

@property (nonatomic, assign) IBOutlet NSWindow *window;
@property (nonatomic, readonly) NSWindowController *preferencesWindowController;

- (IBAction)openPreferences:(id)sender;

@end
