//
//  DMTabBar.h
//  DMTabBar - XCode like Segmented Control
//
//  Created by Daniele Margutti on 6/18/12.
//  Copyright (c) 2012 Daniele Margutti (http://www.danielemargutti.com - daniele.margutti@gmail.com). All rights reserved.
//  Licensed under MIT License
//

#import <Cocoa/Cocoa.h>
#import "DMTabBarItem.h"

enum {
    DMTabBarItemSelectionType_WillSelect    = 0,        // Selection of the item will happend
    DMTabBarItemSelectionType_DidSelect     = 1         // Selection is changed
}; typedef NSUInteger DMTabBarItemSelectionType;

//  This is the event called by DMTabBar when an events occur. DMTabBar will post two kinds of events,
//  when a selection will change and when a change has occurred
typedef void (^DMTabBarEventsHandler)(DMTabBarItemSelectionType selectionType, DMTabBarItem *targetTabBarItem, NSUInteger targetTabBarItemIndex);


@interface DMTabBar : NSView {
    
}

// set an NSArray of DMTabBarItem elements to populate the DMTabBar
@property (nonatomic,strong) NSArray*           tabBarItems;

// change selected item by passing a DMTabBarItem object (ignored if selectedTabBarItem is not contained inside tabBarItems)
@property (nonatomic,assign) DMTabBarItem*      selectedTabBarItem;

// change selected item by passing a new index { 0 < index < tabBarItems.count }
@property (nonatomic,assign) NSUInteger         selectedIndex;


// Handle selection change events using blocks
- (void) handleTabBarItemSelection:(DMTabBarEventsHandler) selectionHandler;

@end
