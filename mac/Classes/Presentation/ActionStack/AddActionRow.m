
#import "AddActionRow.h"
#import "ActionList.h"

@implementation AddActionRow

- (void)loadContent {
    [super loadContent];
    [self updateMenu];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMenu) name:UserScriptManagerScriptsDidChangeNotification object:nil];
}

- (void)updateMenu {
    [super updateMenu];

    NSMenuItem *item = [self.menu addItemWithTitle:@"Run custom command" action:@selector(addActionClicked:) keyEquivalent:@""];
    item.representedObject = @{@"action": @"command"};
    item.target = self;

    [self.menu addItem:[NSMenuItem separatorItem]];

    NSArray *userScripts = [UserScriptManager sharedUserScriptManager].userScripts;
    if (userScripts.count > 0) {
        for (UserScript *userScript in userScripts) {
            NSMenuItem *item = [self.menu addItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Run %@", nil), userScript.friendlyName] action:@selector(addActionClicked:) keyEquivalent:@""];
            item.representedObject = @{@"action": @"script", @"script": userScript.uniqueName};
            item.target = self;
        }
    } else {
        NSMenuItem *item = [self.menu addItemWithTitle:NSLocalizedString(@"No scripts installed", nil) action:nil keyEquivalent:@""];
        item.enabled = NO;
    }

    [self.menu addItem:[NSMenuItem separatorItem]];
    
    item = [self.menu addItemWithTitle:NSLocalizedString(@"Reveal Scripts Folder in Finder", nil) action:@selector(revealScriptsFolderClicked:) keyEquivalent:@""];
    item.target = self;
}

- (IBAction)revealScriptsFolderClicked:(id)sender {
    [[UserScriptManager sharedUserScriptManager] revealUserScriptsFolderSelectingScript:nil];
}

@end
