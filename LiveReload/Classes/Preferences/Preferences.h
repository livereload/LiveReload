
#import <Foundation/Foundation.h>

#define EventProcessingDelayKey @"EventProcessingDelay"


@interface Preferences : NSObject {
    NSDictionary *_builtinMonitoringSettings;
    NSArray *_builtInExtensions;
    NSSet *_allExtensions;
    NSSet *_excludedNames;
}

+ (Preferences *)sharedPreferences;

+ (void)initDefaults;

@property(nonatomic, readonly, copy) NSSet *allExtensions;
@property(nonatomic, readonly, copy) NSArray *builtInExtensions;
@property(nonatomic, retain) NSArray *additionalExtensions;
@property(nonatomic) BOOL autoreloadJavascript;
@property(nonatomic, readonly, copy) NSSet *excludedNames;

@end

extern NSString *PreferencesFilterSettingsChangedNotification;
