
#import <Foundation/Foundation.h>


@interface ActionType : NSObject

@property(nonatomic, copy) NSString *identifier;
@property(nonatomic, assign) Class klass;

- (id)initWithClass:(Class)klass;

@end
