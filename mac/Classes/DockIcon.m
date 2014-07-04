
#import "DockIcon.h"

#import <Cocoa/Cocoa.h>
#import <CoreServices/CoreServices.h>


static BOOL IsOSX107LionOrLater() {
    return YES;
//    SInt32 major = 0;
//    SInt32 minor = 0;
//    Gestalt(gestaltSystemVersionMajor, &major);
//    Gestalt(gestaltSystemVersionMinor, &minor);
//    return ((major == 10 && minor >= 7) || major >= 11);
}


#define DockStateChangeRateLimit 0.5
#define DockIconVisibilityModeKey @"AppVisibilityMode"


static DockIcon *currentDockIcon;


@interface DockIcon ()

- (void)update;

@property(nonatomic) BOOL menuBarIconVisible;

@end


@implementation DockIcon {
    NSMutableSet     *_delegateClasses;
    BOOL              _dockIconVisible;
    NSTimeInterval    _lastDockStateChange;

    BOOL              _menuBarIconVisible;
    NSInteger         _temporaryMenuBarIconRequests;
    NSMutableSet     *_permanentMenuBarIconRequests;

    AppVisibilityMode _visibilityMode;
    BOOL              _visibilityModeRequiresRestartToApply;
}

@synthesize visibilityMode=_visibilityMode;
@synthesize visibilityModeRequiresRestartToApply=_visibilityModeRequiresRestartToApply;
@synthesize menuBarIconVisible=_menuBarIconVisible;


+ (DockIcon *)currentDockIcon {
    if (!currentDockIcon) {
        currentDockIcon = [[DockIcon alloc] init];
    }
    return currentDockIcon;
}

- (id)init {
    self = [super init];
    if (self) {
        _delegateClasses = [[NSMutableSet alloc] init];
        _permanentMenuBarIconRequests = [[NSMutableSet alloc] init];

        [self loadVisibilityMode];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scheduleUpdateSoon) name:NSWindowWillCloseNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update) name:NSWindowDidBecomeKeyNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update) name:NSWindowDidBecomeMainNotification object:nil];
    }
    return self;
}


#pragma mark - Per-window Dock icon mode override

- (void)displayDockIconWhenAppHasWindowsWithDelegateClass:(Class)klass {
    [_delegateClasses addObject:klass];
    [self update];
}

- (BOOL)doesAppHaveAnySpecialWindowsOpen {
    NSApplication *application = NSApp;
    for (NSWindow *window in application.windows) {
        if ([window isVisible]) {
            Class delegateClass = [window.delegate class];
            if (delegateClass && [_delegateClasses containsObject:delegateClass]) {
                return YES;
            }
        }
    }
    return NO;
}


#pragma mark - Dock icon visibility

- (BOOL)shouldDisplayDockIcon {
    return (_visibilityMode == AppVisibilityModeDock) || (IsOSX107LionOrLater() && [self doesAppHaveAnySpecialWindowsOpen]);
}

- (void)scheduleUpdateSoon {
    [self performSelector:@selector(update) withObject:nil afterDelay:0.0];
}


#pragma mark - Menu bar icon visibility

- (BOOL)shouldDisplayMenuBarIcon {
    return _temporaryMenuBarIconRequests > 0 || [_permanentMenuBarIconRequests count] > 0 || _visibilityMode == AppVisibilityModeMenuBar;
}

- (void)showMenuBarIconForDuration:(NSTimeInterval)duration {
    ++_temporaryMenuBarIconRequests;
    [self update];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        --_temporaryMenuBarIconRequests;
        [self update];
    });
}

- (void)setMenuBarIconVisibility:(BOOL)visibility forRequestKey:(NSString *)key gracePeriod:(NSTimeInterval)gracePeriod {
    if (visibility) {
        if (![_permanentMenuBarIconRequests containsObject:key]) {
            [_permanentMenuBarIconRequests addObject:key];
            [self update];
        }
    } else {
        if ([_permanentMenuBarIconRequests containsObject:key]) {
            [_permanentMenuBarIconRequests removeObject:key];
            if (gracePeriod > 0.0) {
                [self showMenuBarIconForDuration:gracePeriod];
            } else {
                [self update];
            }
        }
    }
}

- (void)setMenuBarIconVisibility:(BOOL)visibility forRequestKey:(NSString *)key {
    [self setMenuBarIconVisibility:visibility forRequestKey:key gracePeriod:0.0];
}


#pragma mark - Dock & menu bar icon visibility

- (void)update {
    BOOL shouldBeVisible = [self shouldDisplayDockIcon];
    if (shouldBeVisible != _dockIconVisible) {
        // before OS X 10.6, it is impossible to turn off the Dock icon once it is visible
        if (_dockIconVisible && !shouldBeVisible && !IsOSX107LionOrLater()) {
            _visibilityModeRequiresRestartToApply = YES;
            return;
        }

        // Workaround for a Dock bug noticed on 10.7.3: showing and hiding the icon rapidly
        // causes multiple icons to appear, and those extra icons won't disappear on quit.
        // A workaround is to limit the rate of transitions (once/0.4s seems enough,
        // once/0.5s to be safe).
        NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
        NSTimeInterval remainingDelay = DockStateChangeRateLimit - (now - _lastDockStateChange);
        if (remainingDelay > 0) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(update) object:nil];
            [self performSelector:@selector(update) withObject:nil afterDelay:remainingDelay];
            return;
        }

        _dockIconVisible = shouldBeVisible;

        ProcessSerialNumber psn = { 0, kCurrentProcess };
        if (shouldBeVisible) {
            TransformProcessType(&psn, kProcessTransformToForegroundApplication);
            [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
        } else {
            TransformProcessType(&psn, kProcessTransformToUIElementApplication);
        }

        _lastDockStateChange = [NSDate timeIntervalSinceReferenceDate];
    }
    
    self.menuBarIconVisible = [self shouldDisplayMenuBarIcon];
}


#pragma mark - Visibility mode

- (AppVisibilityMode)defaultVisibilityMode {
    if (IsOSX107LionOrLater())
        return AppVisibilityModeMenuBar;
    else
        return AppVisibilityModeDock;
}

- (void)loadVisibilityMode {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if ([[defaults objectForKey:DockIconVisibilityModeKey] isKindOfClass:[NSString class]]) {
        NSString *value = [defaults objectForKey:DockIconVisibilityModeKey];
        if ([value isEqualToString:@"none"])
            _visibilityMode = AppVisibilityModeNone;
        else if ([value isEqualToString:@"dock"])
            _visibilityMode = AppVisibilityModeDock;
        else if ([value isEqualToString:@"menubar"])
            _visibilityMode = AppVisibilityModeMenuBar;
        else
            _visibilityMode = [self defaultVisibilityMode];
    } else {
        _visibilityMode = [self defaultVisibilityMode];        
    }
}

- (void)saveVisibilityMode {
    NSString *mode = nil;
    if (_visibilityMode == AppVisibilityModeNone)
        mode = @"none";
    else if (_visibilityMode == AppVisibilityModeDock)
        mode = @"dock";
    else if (_visibilityMode == AppVisibilityModeMenuBar)
        mode = @"menubar";
    else {
        NSAssert(NO, @"Invalid value of _visibilityMode");
        return;
    }

    [[NSUserDefaults standardUserDefaults] setObject:mode forKey:DockIconVisibilityModeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setVisibilityMode:(AppVisibilityMode)visibilityMode {
    if (_visibilityMode != visibilityMode) {
        _visibilityMode = visibilityMode;
        [self saveVisibilityMode];

        BOOL prev = _visibilityModeRequiresRestartToApply;
        [self update];

        if (_visibilityModeRequiresRestartToApply && !prev) {
            [[NSAlert alertWithMessageText:@"Restart required" defaultButton:@"Okay" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please restart the app to apply changes to the Dock icon visibility."] runModal];
        } else if (_visibilityMode == AppVisibilityModeMenuBar && IsOSX107LionOrLater()) {
            static BOOL alreadyWarned = NO;
            if (!alreadyWarned) {
                alreadyWarned = YES;

                [[NSAlert alertWithMessageText:@"Please note" defaultButton:@"Okay" alternateButton:nil otherButton:nil informativeTextWithFormat:@"In menu bar mode, LiveReload will still appear in Dock as long as its window is open."] runModal];
            }
        }
    }
}

@end
