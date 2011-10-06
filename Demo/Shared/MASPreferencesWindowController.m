//
//  Created by Vadim Shpakovski on 4/22/11.
//  Copyright 2011 Shpakovski. All rights reserved.
//

#import "MASPreferencesViewController.h"
#import "MASPreferencesWindowController.h"

NSString *const kMASPreferencesWindowControllerDidChangeViewNotification = @"MASPreferencesWindowControllerDidChangeViewNotification";

@interface MASPreferencesWindowController () // Private

- (void)updateViewControllerWithAnimation:(BOOL)animate;

@end

#pragma mark -

@implementation MASPreferencesWindowController

@synthesize viewControllers = _viewControllers;
@synthesize title = _title;

#pragma mark -

- (id)initWithViewControllers:(NSArray *)viewControllers
{
    return [self initWithViewControllers:viewControllers title:nil];
}

- (id)initWithViewControllers:(NSArray *)viewControllers title:(NSString *)title
{
    if ((self = [super initWithWindowNibName:@"MASPreferencesWindow"]))
    {
        _viewControllers = [viewControllers retain];
        _title = [title copy];
    }
    return self;
}

- (void)dealloc
{
    [[self window] setDelegate:nil];
    
    [_viewControllers release];
    [_title release];
    
    [super dealloc];
}

#pragma mark -

- (void)windowDidLoad
{
    if ([self.title length] > 0)
        [[self window] setTitle:self.title];
    [self selectControllerAtIndex:0 withAnimation:NO];
}

#pragma mark -
#pragma mark NSWindowDelegate

- (void)commitPreferences
{
    [[self window] makeFirstResponder:[self window]];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self commitPreferences];
}

- (void)windowDidResignKey:(NSNotification *)notification
{
    [self commitPreferences];
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
    [self resetFirstResponderInView:[[self window] contentView]];
}

#pragma mark -
#pragma mark Accessors

- (NSArray *)toolbarItemIdentifiers
{
    NSArray *identifiers = [_viewControllers valueForKey:@"toolbarItemIdentifier"];
    return identifiers;
}

#pragma mark -

- (NSUInteger)indexOfSelectedController
{
    NSString *selectedIdentifier = self.window.toolbar.selectedItemIdentifier;
    NSArray *identifiers = self.toolbarItemIdentifiers;
    NSUInteger selectedIndex = [identifiers indexOfObject:selectedIdentifier];
    return selectedIndex;
}

- (NSViewController *)selectedViewController
{
    NSString *selectedIdentifier = self.window.toolbar.selectedItemIdentifier;
    NSArray *identifiers = self.toolbarItemIdentifiers;
    NSUInteger selectedIndex = [identifiers indexOfObject:selectedIdentifier];
    NSViewController *selectedController = nil;
    if (NSLocationInRange(selectedIndex, NSMakeRange(0, self.viewControllers.count)))
        selectedController = [self.viewControllers objectAtIndex:selectedIndex];
    return selectedController;
}

#pragma mark -
#pragma mark NSToolbarDelegate

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    NSArray *identifiers = self.toolbarItemIdentifiers;
    return identifiers;
}                   
                   
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    NSArray *identifiers = self.toolbarItemIdentifiers;
    return identifiers;
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
    NSArray *identifiers = self.toolbarItemIdentifiers;
    return identifiers;
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    NSArray *identifiers = self.toolbarItemIdentifiers;
    NSUInteger controllerIndex = [identifiers indexOfObject:itemIdentifier];
    if (controllerIndex != NSNotFound)
    {
        id <MASPreferencesViewController> controller = [_viewControllers objectAtIndex:controllerIndex];
        toolbarItem.image = controller.toolbarItemImage;
        toolbarItem.label = controller.toolbarItemLabel;
        toolbarItem.target = self;
        toolbarItem.action = @selector(toolbarItemDidClick:);
    }
    return [toolbarItem autorelease];
}

#pragma mark -
#pragma mark Private methods

- (void)clearResponderChain
{
    // Remove view controller from the responder chain
    NSResponder *chainedController = self.window.nextResponder;
    if ([self.viewControllers indexOfObject:chainedController] == NSNotFound)
        return;
    self.window.nextResponder = chainedController.nextResponder;
    chainedController.nextResponder = nil;
}

- (void)patchResponderChain
{
    [self clearResponderChain];
    
    NSViewController *selectedController = self.selectedViewController;
    if (!selectedController)
        return;
    
    // Add current controller to the responder chain
    NSResponder *nextResponder = self.window.nextResponder;
    self.window.nextResponder = selectedController;
    selectedController.nextResponder = nextResponder;
}

#pragma mark -

- (void)updateViewControllerWithAnimation:(BOOL)animate
{
    // Retrieve currently selected view controller
    NSArray *identifiers = self.toolbarItemIdentifiers;
    NSString *itemIdentifier = self.window.toolbar.selectedItemIdentifier;
    NSUInteger controllerIndex = [identifiers indexOfObject:itemIdentifier];
    if (controllerIndex == NSNotFound) return;
    NSViewController <MASPreferencesViewController> *controller = [_viewControllers objectAtIndex:controllerIndex];
    
    // Retrieve the new window tile from the controller view
    if ([self.title length] == 0)
    {
        NSString *label = controller.toolbarItemLabel;
        self.window.title = label;
    }
    
    // Retrieve the view to place into window
    NSView *controllerView = controller.view;
    
    // Calculate new window size and position
    NSRect oldFrame = [self.window frame];
    NSRect newFrame = [self.window frameRectForContentRect:controllerView.bounds];
    newFrame = NSOffsetRect(newFrame, NSMinX(oldFrame), NSMaxY(oldFrame) - NSMaxY(newFrame));

    // Setup min/max sizes and show/hide resize indicator
    BOOL sizableWidth  = [controllerView autoresizingMask] & NSViewWidthSizable;
    BOOL sizableHeight = [controllerView autoresizingMask] & NSViewHeightSizable;
    [self.window setContentMinSize:NSMakeSize(sizableWidth ?         200 : NSWidth(controllerView.bounds), sizableHeight ?         200 : NSHeight(controllerView.bounds))];
    [self.window setContentMaxSize:NSMakeSize(sizableWidth ? CGFLOAT_MAX : NSWidth(controllerView.bounds), sizableHeight ? CGFLOAT_MAX : NSHeight(controllerView.bounds))];
    [self.window setShowsResizeIndicator:sizableWidth || sizableHeight];
    
    // Place the view into window and perform reposition
    NSView *contentView = self.window.contentView;
    NSArray *subviews = [contentView.subviews retain];
    for (NSView *subview in contentView.subviews)
        [subview removeFromSuperviewWithoutNeedingDisplay];
    [subviews release];
    [self.window setFrame:newFrame display:YES animate:animate];
    
    if ([_lastSelectedController respondsToSelector:@selector(viewDidDisappear)])
        [_lastSelectedController viewDidDisappear];
    if ([controller respondsToSelector:@selector(viewWillAppear)])
        [controller viewWillAppear];
    _lastSelectedController = controller;
    
    // Add controller view only after animation is ended to avoid blinking
    if (animate)
        [self performSelector:@selector(setContentView:) withObject:controllerView afterDelay:0.0];
    else
        [self performSelector:@selector(setContentView:) withObject:controllerView];
    
    // Insert view controller into responder chain
    [self patchResponderChain];
}

- (void)resetFirstResponderInView:(NSView *)view
{
    BOOL isNotButton = ![view isKindOfClass:[NSButton class]];
    BOOL canBecomeKey = view.canBecomeKeyView;
    if (isNotButton && canBecomeKey)
    {
        [self.window makeFirstResponder:view];
    }
    else
    {
        for (NSView *subview in view.subviews)
            [self resetFirstResponderInView:subview];
    }
}

- (void)setContentView:(NSView *)view
{
    [self.window.contentView addSubview:view];
    [self resetFirstResponderInView:self.window.contentView];
}

- (void)toolbarItemDidClick:(id)sender
{
    [self updateViewControllerWithAnimation:YES];

    [[NSNotificationCenter defaultCenter] postNotificationName:kMASPreferencesWindowControllerDidChangeViewNotification object:self];
}

#pragma mark -
#pragma mark Public methods

- (void)selectControllerAtIndex:(NSUInteger)controllerIndex withAnimation:(BOOL)animate
{
    if (!NSLocationInRange(controllerIndex, NSMakeRange(0, _viewControllers.count)))
        return;

    NSViewController <MASPreferencesViewController> *controller = [_viewControllers objectAtIndex:controllerIndex];
    NSString *newItemIdentifier = controller.toolbarItemIdentifier;
    self.window.toolbar.selectedItemIdentifier = newItemIdentifier;
    [self updateViewControllerWithAnimation:animate];
}

#pragma mark -
#pragma mark Actions

- (IBAction)goNextTab:(id)sender
{
    NSUInteger selectedIndex = self.indexOfSelectedController;
    NSUInteger numberOfControllers = [_viewControllers count];
    selectedIndex = (selectedIndex + 1) % numberOfControllers;
    [self selectControllerAtIndex:selectedIndex withAnimation:YES];
}

- (IBAction)goPreviousTab:(id)sender
{
    NSUInteger selectedIndex = self.indexOfSelectedController;
    NSUInteger numberOfControllers = [_viewControllers count];
    selectedIndex = (selectedIndex + numberOfControllers - 1) % numberOfControllers;
    [self selectControllerAtIndex:selectedIndex withAnimation:YES];
}

@end
