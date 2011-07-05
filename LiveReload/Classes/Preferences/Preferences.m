
#import "Preferences.h"
#import "PluginManager.h"


#define AdditionalExtensionsKey @"additionalExtensions"

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

- (NSSet *)additionalExtensions {
    return [NSSet setWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:AdditionalExtensionsKey]];
}

- (void)setAdditionalExtensions:(NSSet *)additionalExtensions {
    [[NSUserDefaults standardUserDefaults] setObject:[additionalExtensions allObjects] forKey:AdditionalExtensionsKey];
}


#pragma mark - Filter preferences

- (void)updateFilterPreferencesSilently {
    NSMutableSet *extensions = [NSMutableSet setWithArray:[_builtinMonitoringSettings objectForKey:@"extensions"]];
    [extensions unionSet:self.additionalExtensions];
    [extensions addObjectsFromArray:[PluginManager sharedPluginManager].compilerSourceExtensions];
    self.allExtensions = extensions;
    self.excludedNames = [NSSet setWithArray:[_builtinMonitoringSettings objectForKey:@"excludedNames"]];
}

- (void)updateFilterPreferences {
    [self updateFilterPreferencesSilently];
    [[NSNotificationCenter defaultCenter] postNotificationName:PreferencesFilterSettingsChangedNotification object:self];
}

@end
