
#import <Foundation/Foundation.h>


@interface CompilerVersion : NSObject {
@private
    NSString           *_name;
}

- (id)initWithName:(NSString *)name;

@property(nonatomic, readonly) NSString *name;

@end
