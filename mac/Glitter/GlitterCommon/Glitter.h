
#import <Foundation/Foundation.h>

#import "GlitterGlobals.h"


@interface Glitter : NSObject

- (id)initWithMainBundle;

@property(nonatomic, copy) NSString *channelName;

- (void)checkForUpdatesWithOptions:(GlitterCheckOptions)options;

@end
