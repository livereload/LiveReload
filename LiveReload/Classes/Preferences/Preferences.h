
#import <Foundation/Foundation.h>

#define EventProcessingDelayKey @"MinEventProcessingDelay"


@interface Preferences : NSObject {
    NSDictionary *_builtinMonitoringSettings;
    NSArray *_builtInExtensions;
    NSSet *_allExtensions;
    NSSet *_excludedNames;
}

+ (Preferences *)sharedPreferences;

+ (void)initDefaults;

@property(nonatomic, readonly, copy) NSArray<NSString *> *builtInExtensions;
@property(nonatomic, retain) NSArray<NSString *> *additionalExtensions;
@property(nonatomic) BOOL autoreloadJavascript;
@property(nonatomic, readonly, copy) NSSet *excludedNames;

@end

extern NSString *PreferencesFilterSettingsChangedNotification;
