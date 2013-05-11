
#import <Foundation/Foundation.h>


@class RuntimeManager;
@class RuntimeInstance;
@class RuntimeVariant;


extern NSString *const LRRuntimeManagerErrorDomain;
enum {
    LRRuntimeManagerErrorValidationFailed = 1,
};

extern NSString *const LRRuntimesDidChangeNotification;

void PostRuntimesDidChangeNotification();


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


@interface RuntimeContainer : NSObject

- (id)initWithDictionary:(NSDictionary *)data;

@property(nonatomic, readonly) NSMutableDictionary *memento;

@property(nonatomic, readonly) BOOL exposedToUser;  // if NO, container name will not be displayed
@property(nonatomic, readonly) NSString *title;
@property(nonatomic, readonly) NSArray *instances;

@property(nonatomic, strong, __unsafe_unretained) RuntimeManager *manager; // FIXME

- (void)validateAndDiscover;

@end

//@interface RuntimeVariant : NSObject
//
//@end
