
#import <Foundation/Foundation.h>


@interface FSTreeFilter : NSObject {
    NSSet *_enabledExtensions;
}

@property(nonatomic, copy) NSSet *enabledExtensions;

- (BOOL)acceptsFileName:(NSString *)name;

@end
