//
//  DMTabBarItem.m
//  DMTabBar - XCode like Segmented Control
//
//  Created by Daniele Margutti on 6/18/12.
//  Copyright (c) 2012 Daniele Margutti (http://www.danielemargutti.com - daniele.margutti@gmail.com). All rights reserved.
//  Licensed under MIT License
//

#import "DMTabBarItem.h"

static CGFloat kDMTabBarItemGradientColor_Locations[] =     {0.0f, 0.5f, 1.0f};

#define kDMTabBarItemGradientColor1                         [NSColor colorWithCalibratedWhite:0.7f alpha:0.0f]
#define kDMTabBarItemGradientColor2                         [NSColor colorWithCalibratedWhite:0.7f alpha:1.0f]
#define kDMTabBarItemGradient                               [[NSGradient alloc] initWithColors: [NSArray arrayWithObjects: \
                                                                                                         kDMTabBarItemGradientColor1, \
                                                                                                         kDMTabBarItemGradientColor2, \
                                                                                                         kDMTabBarItemGradientColor1, nil] \
                                                                                   atLocations: kDMTabBarItemGradientColor_Locations \
                                                                                    colorSpace: [NSColorSpace genericGrayColorSpace]]

@interface DMTabBarButtonCell : NSButtonCell { }
@end

@interface DMTabBarItem() {
    NSButton*       tabBarItemButton;
}
@end

@implementation DMTabBarItem

@synthesize enabled,icon,toolTip;
@synthesize keyEquivalent,keyEquivalentModifierMask;
@synthesize tag;
@synthesize tabBarItemButton;
@synthesize state;

+ (DMTabBarItem *) tabBarItemWithIcon:(NSImage *) iconImage tag:(NSUInteger) itemTag {
    return [[DMTabBarItem alloc] initWithIcon:iconImage tag:itemTag];
}

- (id)initWithIcon:(NSImage *) iconImage tag:(NSUInteger) itemTag {
    self = [super init];
    if (self) {
        // Create associated NSButton to place inside the bar (it's customized by DMTabBarButtonCell with a special gradient for selected state)
        tabBarItemButton = [[NSButton alloc] initWithFrame:NSZeroRect];
        tabBarItemButton.cell = [[DMTabBarButtonCell alloc] init];
        tabBarItemButton.image = iconImage;
        [tabBarItemButton setEnabled:YES];
        tabBarItemButton.tag = itemTag;
        [tabBarItemButton sendActionOn:NSLeftMouseDownMask];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"[DMTabBarItem] tag=%i - title=%@", self.tag,self.title];
}

#pragma mark - Properties redirects

// We simply redirects properties to the the NSButton class

- (void) setIcon:(NSImage *)newIcon { 
    tabBarItemButton.image = newIcon;   
}

- (NSImage *) icon {   
    return tabBarItemButton.image;  
}

- (void) setTag:(NSUInteger)newTag {  
    tabBarItemButton.tag = newTag; 
}

- (NSUInteger) tag {  
    return tabBarItemButton.tag;    
}

- (void) setToolTip:(NSString *)newToolTip {   
    tabBarItemButton.toolTip = newToolTip;  
}

- (NSString *) toolTip {  
    return tabBarItemButton.toolTip;    
}

- (void) setKeyEquivalentModifierMask:(NSUInteger)newKeyEquivalentModifierMask {
    tabBarItemButton.keyEquivalentModifierMask = newKeyEquivalentModifierMask; 
}

- (NSUInteger) keyEquivalentModifierMask {
    return tabBarItemButton.keyEquivalentModifierMask; 
}

- (void) setKeyEquivalent:(NSString *)newKeyEquivalent {
    tabBarItemButton.keyEquivalent = newKeyEquivalent;
}

- (NSString *) keyEquivalent { 
    return tabBarItemButton.keyEquivalent;  
}

- (void) setState:(NSInteger)value {
    tabBarItemButton.state = value;
}

- (NSInteger) state {
    return tabBarItemButton.state;
}

@end


#pragma mark - DMTabBarButtonCell

@implementation DMTabBarButtonCell

- (id)init {
    self = [super init];
    if (self) {
        self.bezelStyle = NSTexturedRoundedBezelStyle;
    }
    return self;
}

- (NSInteger) nextState {
    return self.state;
}

- (void) drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView {
    if (self.state == NSOnState) { 
        // If selected we need to draw the border new background for selection (otherwise we will use default back color)
        // Save current context
        [[NSGraphicsContext currentContext] saveGraphicsState];
        
        // Draw light vertical gradient
        [kDMTabBarItemGradient drawInRect:frame angle:-90.0f];
        
        // Draw shadow on the left border of the item
        NSShadow *shadow = [[NSShadow alloc] init];
        shadow.shadowOffset = NSMakeSize(1.0f, 0.0f);
        shadow.shadowBlurRadius = 2.0f;
        shadow.shadowColor = [NSColor darkGrayColor];
        [shadow set];
        
        [[NSColor blackColor] set];        
        CGFloat radius = 50.0;
        NSPoint center = NSMakePoint(NSMinX(frame) - radius, NSMidY(frame));
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:center];
        [path appendBezierPathWithArcWithCenter:center radius:radius startAngle:-90.0f endAngle:90.0f];
        [path closePath];
        [path fill];
        
        // shadow of the right border
        shadow.shadowOffset = NSMakeSize(-1.0f, 0.0f);
        [shadow set];
        
        center = NSMakePoint(NSMaxX(frame) + radius, NSMidY(frame));
        path = [NSBezierPath bezierPath];
        [path moveToPoint:center];
        [path appendBezierPathWithArcWithCenter:center radius:radius startAngle:90.0f  endAngle:270.0f];
        [path closePath];
        [path fill];
        
        // Restore context
        [[NSGraphicsContext currentContext] restoreGraphicsState];
    }
}
@end
