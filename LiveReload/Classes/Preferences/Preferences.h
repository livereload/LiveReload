
#import <Foundation/Foundation.h>

#define EventProcessingDelayKey @"EventProcessingDelay"


@interface Preferences : NSObject {
    NSDictionary *_builtinMonitoringSettings;
    NSSet *_allExtensions;
    NSSet *_excludedNames;
}

+ (Preferences *)sharedPreferences;

+ (void)initDefaults;

@property(nonatomic, readonly, copy) NSSet *allExtensions;
@property(nonatomic, retain) NSSet *additionalExtensions;
@property(nonatomic) BOOL autoreloadJavascript;
@property(nonatomic, readonly, copy) NSSet *excludedNames;

@end

extern NSString *PreferencesFilterSettingsChangedNotification;
