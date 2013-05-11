
#import <Foundation/Foundation.h>

@interface PreferencesController : NSObject

+ (PreferencesController *)sharedPreferencesController;

- (void)show;
- (void)showAddRubyInstancePage;

@end
