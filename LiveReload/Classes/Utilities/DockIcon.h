
#import <Foundation/Foundation.h>


@interface DockIcon : NSObject

+ (DockIcon *)currentDockIcon;

- (void)displayDockIconWhenAppHasWindowsWithDelegateClass:(Class)klass;

@end
