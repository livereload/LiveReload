//
//  DMAppDelegate.m
//  DMTabBar
//
//  Created by Daniele Margutti on 6/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DMAppDelegate.h"
#import "DMTabBar.h"

#define kTabBarElements     [NSArray arrayWithObjects: \
                                [NSDictionary dictionaryWithObjectsAndKeys: [NSImage imageNamed:@"tabBarItem1"],@"image",@"Tab #1",@"title",nil], \
                                [NSDictionary dictionaryWithObjectsAndKeys: [NSImage imageNamed:@"tabBarItem2"],@"image",@"Tab #2",@"title",nil], \
                                [NSDictionary dictionaryWithObjectsAndKeys: [NSImage imageNamed:@"tabBarItem3"],@"image",@"Tab #3",@"title",nil],nil]

@interface DMAppDelegate() {
    IBOutlet    DMTabBar*   tabBar;
    IBOutlet    NSTabView*  tabView;
}

@end

@implementation DMAppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:2];
    
    // Create an array of DMTabBarItem objects
    [kTabBarElements enumerateObjectsUsingBlock:^(NSDictionary* objDict, NSUInteger idx, BOOL *stop) {
        NSImage *iconImage = [objDict objectForKey:@"image"];
        [iconImage setTemplate:YES];
        
        DMTabBarItem *item1 = [DMTabBarItem tabBarItemWithIcon:iconImage tag:idx];
        item1.toolTip = [objDict objectForKey:@"title"];
        item1.keyEquivalent = [NSString stringWithFormat:@"%d",idx];
        item1.keyEquivalentModifierMask = NSCommandKeyMask;
        [items addObject:item1];
    }];
    
    // Load them
    tabBar.tabBarItems = items;
    
    // Handle selection events
    [tabBar handleTabBarItemSelection:^(DMTabBarItemSelectionType selectionType, DMTabBarItem *targetTabBarItem, NSUInteger targetTabBarItemIndex) {
        if (selectionType == DMTabBarItemSelectionType_WillSelect) {
            //NSLog(@"Will select %lu/%@",targetTabBarItemIndex,targetTabBarItem);
            [tabView selectTabViewItem:[tabView.tabViewItems objectAtIndex:targetTabBarItemIndex]];
        } else if (selectionType == DMTabBarItemSelectionType_DidSelect) {
            //NSLog(@"Did select %lu/%@",targetTabBarItemIndex,targetTabBarItem);
        }
    }];
}

@end
