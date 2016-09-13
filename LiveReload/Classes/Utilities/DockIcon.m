
#import "DockIcon.h"

#import <Cocoa/Cocoa.h>
#import <CoreServices/CoreServices.h>


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
}

@synthesize visibilityMode=_visibilityMode;
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
    return (_visibilityMode == AppVisibilityModeDock) || [self doesAppHaveAnySpecialWindowsOpen];
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
    return AppVisibilityModeMenuBar;
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

        [self update];

        if (_visibilityMode == AppVisibilityModeMenuBar) {
            static BOOL alreadyWarned = NO;
            if (!alreadyWarned) {
                alreadyWarned = YES;

                [[NSAlert alertWithMessageText:@"Please note" defaultButton:@"Okay" alternateButton:nil otherButton:nil informativeTextWithFormat:@"In menu bar mode, LiveReload will still appear in Dock as long as its window is open."] runModal];
            }
        }
    }
}

@end
