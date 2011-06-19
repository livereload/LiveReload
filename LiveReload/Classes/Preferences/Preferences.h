
#import <Foundation/Foundation.h>


@interface Preferences : NSObject {
    NSDictionary *_builtinMonitoringSettings;
    NSSet *_allExtensions;
}

+ (Preferences *)sharedPreferences;

@property(nonatomic, readonly, copy) NSSet *allExtensions;
@property(nonatomic, retain) NSSet *additionalExtensions;

@end

extern NSString *PreferencesFilterSettingsChangedNotification;
