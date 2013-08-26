
#import <Foundation/Foundation.h>
#import "Action.h"


@interface ActionType : NSObject

@property(nonatomic) ActionKind kind;
@property(nonatomic, copy) NSString *identifier;
@property(nonatomic, assign) Class klass;

- (id)initWithClass:(Class)klass;

@end
