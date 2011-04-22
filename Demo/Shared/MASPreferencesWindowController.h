//
//  Created by Vadim Shpakovski on 4/22/11.
//  Copyright 2011 Shpakovski. All rights reserved.
//

extern NSString *const kMASPreferencesWindowControllerDidChangeViewNotification;

@interface MASPreferencesWindowController : NSWindowController <NSToolbarDelegate, NSWindowDelegate>
{
@private
    NSArray *_viewControllers;
    NSString *_title;
    id _lastSelectedController;
}

@property (nonatomic, readonly) NSArray *viewControllers;
@property (nonatomic, readonly) NSUInteger indexOfSelectedController;
@property (nonatomic, readonly) NSViewController *selectedViewController;
@property (nonatomic, readonly) NSString *title;

- (id)initWithViewControllers:(NSArray *)viewControllers;
- (id)initWithViewControllers:(NSArray *)viewControllers title:(NSString *)title;

- (void)selectControllerAtIndex:(NSUInteger)controllerIndex withAnimation:(BOOL)animate;

- (IBAction)goNextTab:(id)sender;
- (IBAction)goPreviousTab:(id)sender;

- (void)resetFirstResponderInView:(NSView *)view;

@end
