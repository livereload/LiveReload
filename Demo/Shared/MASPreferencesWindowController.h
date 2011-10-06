//
//  Created by Vadim Shpakovski on 4/22/11.
//  Copyright 2011 Shpakovski. All rights reserved.
//

extern NSString *const kMASPreferencesWindowControllerDidChangeViewNotification;

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
@interface MASPreferencesWindowController : NSWindowController <NSToolbarDelegate, NSWindowDelegate>
#else
@interface MASPreferencesWindowController : NSWindowController
#endif
{
@private
    NSArray *_viewControllers;
    NSMutableDictionary *_minimumViewRects;
    NSString *_title;
    id _lastSelectedController;
}

@property (nonatomic, readonly) NSArray *viewControllers;
@property (nonatomic, readonly) NSUInteger indexOfSelectedController;
@property (nonatomic, readonly) NSViewController <MASPreferencesViewController> *selectedViewController;
@property (nonatomic, readonly) NSString *title;

- (id)initWithViewControllers:(NSArray *)viewControllers;
- (id)initWithViewControllers:(NSArray *)viewControllers title:(NSString *)title;

- (void)selectControllerAtIndex:(NSUInteger)controllerIndex withAnimation:(BOOL)animate;

- (IBAction)goNextTab:(id)sender;
- (IBAction)goPreviousTab:(id)sender;

- (void)resetFirstResponderInView:(NSView *)view;

@end
