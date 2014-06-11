
#import "Preferences.h"
#import "LiveReload-Swift-x.h"


#define AdditionalExtensionsKey @"additionalExtensions"
#define AutoreloadJavascriptKey @"autoreloadJavascript"

static Preferences *sharedPreferences = nil;

NSString *PreferencesFilterSettingsChangedNotification = @"PreferencesFilterSettingsChangedNotification";



@interface Preferences ()

- (void)updateFilterPreferencesSilently;
- (void)updateFilterPreferences;

@property(nonatomic, copy) NSSet *allExtensions;
@property(nonatomic, copy) NSSet *excludedNames;

@end


@implementation Preferences

@synthesize allExtensions=_allExtensions;
@synthesize builtInExtensions=_builtInExtensions;
@synthesize excludedNames=_excludedNames;

- (id)init {
    self = [super init];
    if (self) {
        _builtinMonitoringSettings = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"monitoring" ofType:@"plist"]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFilterPreferences) name:NSUserDefaultsDidChangeNotification object:nil];
        [self updateFilterPreferencesSilently];
    }

    return self;
}

+ (Preferences *)sharedPreferences {
    if (sharedPreferences == nil) {
        sharedPreferences = [[Preferences alloc] init];
    }
    return sharedPreferences;
}

+ (void)initDefaults {
    NSMutableDictionary * defaults = [NSMutableDictionary dictionaryWithObject:[NSArray array] forKey: AdditionalExtensionsKey];
    [defaults setObject:[NSNumber numberWithBool:NO] forKey: AutoreloadJavascriptKey];
    [defaults setObject:[NSNumber numberWithInteger:100] forKey:EventProcessingDelayKey];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (NSArray *)additionalExtensions {
    return [[NSUserDefaults standardUserDefaults] arrayForKey:AdditionalExtensionsKey];
}

- (void)setAdditionalExtensions:(NSArray *)additionalExtensions {
    [[NSUserDefaults standardUserDefaults] setObject:additionalExtensions forKey:AdditionalExtensionsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)autoreloadJavascript {
    return [[NSUserDefaults standardUserDefaults] boolForKey:AutoreloadJavascriptKey];
}

- (void)setAutoreloadJavascript:(BOOL)autoreloadJavascript {
    [[NSUserDefaults standardUserDefaults] setBool:autoreloadJavascript forKey:AutoreloadJavascriptKey];
}

#pragma mark - Filter preferences

- (void)updateFilterPreferencesSilently {
    _builtInExtensions = [_builtinMonitoringSettings objectForKey:@"extensions"];
    NSMutableSet *extensions = [NSMutableSet setWithArray:_builtInExtensions];
    [extensions unionSet:[NSSet setWithArray:self.additionalExtensions]];
    [extensions addObjectsFromArray:[PluginManager sharedPluginManager].compilerSourceExtensions];
    self.allExtensions = extensions;
    self.excludedNames = [NSSet setWithArray:[_builtinMonitoringSettings objectForKey:@"excludedNames"]];
}

- (void)updateFilterPreferences {
    [self updateFilterPreferencesSilently];
    [[NSNotificationCenter defaultCenter] postNotificationName:PreferencesFilterSettingsChangedNotification object:self];
}

@end
