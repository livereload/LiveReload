//
//  Created by Vadim Shpakovski on 4/22/11.
//  Copyright 2011 Shpakovski. All rights reserved.
//

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
