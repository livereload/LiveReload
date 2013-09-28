
#import <Cocoa/Cocoa.h>


@class Glitter;


@interface GlitterUpdateInfoViewController : NSViewController

- (id)initWithGlitter:(Glitter *)glitter;

@property(nonatomic, readonly, strong) Glitter *glitter;

@end
