
#import <Foundation/Foundation.h>


typedef enum {
    ActionKindFilter,
    ActionKindPostproc,
} ActionKind;


@interface ActionType : NSObject

@property(nonatomic) ActionKind kind;
@property(nonatomic, copy) NSString *identifier;
@property(nonatomic, assign) Class klass;

- (id)initWithClass:(Class)klass kind:(ActionKind)kind;

@end
