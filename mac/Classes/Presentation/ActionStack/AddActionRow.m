
#import "AddActionRow.h"
#import "ActionList.h"

@implementation AddActionRow

- (void)loadContent {
    [super loadContent];
    [self updateMenu];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMenu) name:UserScriptManagerScriptsDidChangeNotification object:nil];
}

- (void)updateMenu {
    NSMenu *menu = self.menuPullDown.menu;

    [menu removeAllItems];
    [menu addItemWithTitle:@"Add action" action:NULL keyEquivalent:@""];

    NSMenuItem *item = [menu addItemWithTitle:@"Run custom command" action:@selector(addActionClicked:) keyEquivalent:@""];
    item.representedObject = @{@"action": @"command"};
    item.target = self;

    [menu addItem:[NSMenuItem separatorItem]];

    NSArray *userScripts = [UserScriptManager sharedUserScriptManager].userScripts;
    if (userScripts.count > 0) {
        for (UserScript *userScript in userScripts) {
            NSMenuItem *item = [menu addItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Run %@", nil), userScript.friendlyName] action:@selector(addActionClicked:) keyEquivalent:@""];
            item.representedObject = @{@"action": @"script", @"script": userScript.uniqueName};
            item.target = self;
        }
    } else {
        NSMenuItem *item = [menu addItemWithTitle:NSLocalizedString(@"No scripts installed", nil) action:nil keyEquivalent:@""];
        item.enabled = NO;
    }

    [menu addItem:[NSMenuItem separatorItem]];
    
    item = [menu addItemWithTitle:NSLocalizedString(@"Reveal Scripts Folder in Finder", nil) action:@selector(revealScriptsFolderClicked:) keyEquivalent:@""];
    item.target = self;
}

- (IBAction)revealScriptsFolderClicked:(id)sender {
    [[UserScriptManager sharedUserScriptManager] revealUserScriptsFolderSelectingScript:nil];
}

@end
