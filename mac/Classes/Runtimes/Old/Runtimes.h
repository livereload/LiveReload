
#import <Foundation/Foundation.h>


@class RuntimeManager;
@class RuntimeInstance;
@class RuntimeVariant;

#import "RuntimeGlobals.h"
extern NSString *const LRRuntimesDidChangeNotification;


@interface RuntimeManager : NSObject

- (void)load;

- (RuntimeInstance *)instanceIdentifiedBy:(NSString *)identifier;

- (void)runtimesDidChange;

- (RuntimeInstance *)newInstanceWithDictionary:(NSDictionary *)memento;

@end


@interface RuntimeInstance : NSObject

@property(nonatomic, readonly) NSString *identifier;
@property(nonatomic, strong) NSString *executablePath;
@property(nonatomic, readonly) NSURL *executableURL;
@property(nonatomic, strong) NSString *basicTitle;  // sans version number

@property(nonatomic, assign) BOOL validationInProgress;
@property(nonatomic, assign) BOOL validationPerformed;
@property(nonatomic, assign) BOOL valid;
@property(nonatomic, strong) NSString *version;

@property(nonatomic, readonly) NSString *statusQualifier;
@property(nonatomic, readonly) NSString *title;

@property(nonatomic, readonly) NSMutableDictionary *memento;

@property(nonatomic, strong, __unsafe_unretained) RuntimeManager *manager;

- (id)initWithDictionary:(NSDictionary *)data;

- (void)validate;

- (void)doValidate; // override point, must call one of the methods below
- (void)validationSucceededWithData:(NSDictionary *)data;
- (void)validationFailedWithError:(NSError *)error;

//@property(nonatomic, readonly) NSArray *librarySets;
//

@end


@interface MissingRuntimeInstance : RuntimeInstance
@end
