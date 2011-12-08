
#import <Foundation/Foundation.h>

#define BrowserRefreshCountStat @"stat.reloads"
#define CompilerChangeCountStatGroup @"stat.compiler"
#define CompilerChangeCountEnabledStatGroup @"stat.compilation"

void StatIncrement(NSString *name, NSInteger delta);
NSInteger StatGet(NSString *name);
void StatToParams(NSString *name, NSMutableDictionary *params);

void StatGroupIncrement(NSString *name, NSString *item, NSInteger delta);
NSArray *StatGroupItems(NSString *name);
void StatGroupToParams(NSString *name, NSMutableDictionary *params);

void StatAllToParams(NSMutableDictionary *params);

typedef void (^AppNewsKitParamBlock_t)(NSMutableDictionary *params);
void AppNewsKitStartup(NSString *pingURL, AppNewsKitParamBlock_t pingParamBlock);
void AppNewsKitGoodTimeToDeliverMessages();
