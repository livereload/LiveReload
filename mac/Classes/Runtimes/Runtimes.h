
#import <Foundation/Foundation.h>


@class RuntimeManager;
@class RuntimeInstance;
@class RuntimeVariant;


extern NSString *const LRRuntimeManagerErrorDomain;
enum {
    LRRuntimeManagerErrorValidationFailed = 1,
};


@interface RuntimeManager : NSObject

- (RuntimeInstance *)instanceIdentifiedBy:(NSString *)identifier;

@end


@interface RuntimeInstance : NSObject

@property(nonatomic, readonly) NSString *identifier;
@property(nonatomic, readonly) NSString *executablePath;
@property(nonatomic, readonly) NSURL *executableURL;
@property(nonatomic, readonly) NSString *basicTitle;  // sans version number

@property(nonatomic, assign) BOOL validationInProgress;
@property(nonatomic, assign) BOOL validationPerformed;
@property(nonatomic, assign) BOOL valid;
@property(nonatomic, strong) NSString *version;

@property(nonatomic, readonly) NSString *statusQualifier;
@property(nonatomic, readonly) NSString *title;

- (id)initWithDictionary:(NSDictionary *)data;

- (void)validate;

- (void)doValidate; // override point, must call one of the methods below
- (void)validationSucceededWithData:(NSDictionary *)data;
- (void)validationFailedWithError:(NSError *)error;

//@property(nonatomic, readonly) NSArray *librarySets;
//

@end

//
//@interface RuntimeContainer : NSObject
//
//@property(nonatomic, readonly) BOOL visible;
//@property(nonatomic, readonly) NSString *title;
//@property(nonatomic, readonly) NSArray *instances;
//
//@end
//
//@interface RuntimeVariant : NSObject
//
//@end
