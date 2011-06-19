
#import <Foundation/Foundation.h>


@interface Preferences : NSObject {
    NSDictionary *_builtinMonitoringSettings;
    NSSet *_allExtensions;
    NSSet *_excludedNames;
}

+ (Preferences *)sharedPreferences;

@property(nonatomic, readonly, copy) NSSet *allExtensions;
@property(nonatomic, retain) NSSet *additionalExtensions;
@property(nonatomic, readonly, copy) NSSet *excludedNames;

@end

extern NSString *PreferencesFilterSettingsChangedNotification;
