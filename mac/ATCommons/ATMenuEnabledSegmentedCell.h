
#import <Cocoa/Cocoa.h>

// Goal: A segmented control with some segments that act like buttons, and some segments
//       act like pop-up menus.
//
// Problem: Normally, a segmented control with an action set only triggers
//          segment menus after click-and-hold (and runs the action on regular click).
//
// Solution: apply this cell to a segmented control, and the segment menus will be displayed on click.

@interface ATMenuEnabledSegmentedCell : NSSegmentedCell
@end
