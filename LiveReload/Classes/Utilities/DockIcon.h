
#import <Foundation/Foundation.h>


typedef enum {
    AppVisibilityModeNone,
    AppVisibilityModeDock,
    AppVisibilityModeMenuBar
} AppVisibilityMode;


@interface DockIcon : NSObject

+ (DockIcon *)currentDockIcon;

- (void)displayDockIconWhenAppHasWindowsWithDelegateClass:(Class)klass;

@property(nonatomic) AppVisibilityMode visibilityMode;

@property(nonatomic, readonly) BOOL menuBarIconVisible;

- (void)showMenuBarIconForDuration:(NSTimeInterval)duration;
- (void)setMenuBarIconVisibility:(BOOL)visibility forRequestKey:(NSString *)key;
- (void)setMenuBarIconVisibility:(BOOL)visibility forRequestKey:(NSString *)key gracePeriod:(NSTimeInterval)gracePeriod;

@end
