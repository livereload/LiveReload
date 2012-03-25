
#import "DockIcon.h"

#import <Cocoa/Cocoa.h>
#import <CoreServices/CoreServices.h>


static BOOL IsOSX107LionOrLater() {
    SInt32 major = 0;
    SInt32 minor = 0;
    Gestalt(gestaltSystemVersionMajor, &major);
    Gestalt(gestaltSystemVersionMinor, &minor);
    return ((major == 10 && minor >= 7) || major >= 11);
}


#define DockStateChangeRateLimit 0.5


static DockIcon *currentDockIcon;


@interface DockIcon ()

- (void)update;

@end


@implementation DockIcon {
    NSMutableSet     *_delegateClasses;
    BOOL              _dockIconVisible;
    NSTimeInterval    _lastDockStateChange;
}

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
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scheduleUpdateSoon) name:NSWindowWillCloseNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update) name:NSWindowDidBecomeKeyNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update) name:NSWindowDidBecomeMainNotification object:nil];
    }
    return self;
}

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

- (BOOL)shouldDisplayDockIcon {
    return IsOSX107LionOrLater() && [self doesAppHaveAnySpecialWindowsOpen];
}

- (void)scheduleUpdateSoon {
    [self performSelector:@selector(update) withObject:nil afterDelay:0.0];
}

- (void)update {
    // Workaround for a Dock bug noticed on 10.7.3: showing and hiding the icon rapidly
    // causes multiple icons to appear, and those extra icons won't disappear on hide.
    // A workaround is to limit the rate of transitions (once/0.4s seems enough,
    // once/0.5s to be safe).
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval remainingDelay = DockStateChangeRateLimit - (now - _lastDockStateChange);
    if (remainingDelay > 0) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(update) object:nil];
        [self performSelector:@selector(update) withObject:nil afterDelay:remainingDelay];
        return;
    }

    BOOL shouldBeVisible = [self shouldDisplayDockIcon];
    if (shouldBeVisible != _dockIconVisible) {
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
}

@end
