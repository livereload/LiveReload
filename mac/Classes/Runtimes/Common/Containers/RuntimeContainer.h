
#import <Foundation/Foundation.h>
#import "RuntimeObject.h"


extern NSString *const LRRuntimeContainerDidChangeNotification;


@class RuntimeInstance;


@interface RuntimeContainer : NSObject <RuntimeObject>

- (id)initWithDictionary:(NSDictionary *)data;

@property(nonatomic, readonly) NSURL *url;
@property(nonatomic, readonly) BOOL validationInProgress;
@property(nonatomic, readonly) BOOL validationPerformed;
@property(nonatomic, readonly) BOOL valid;

@property(nonatomic, readonly) BOOL instanceValidationInProgress;
@property(nonatomic, readonly) BOOL subtreeValidationInProgress;
@property(nonatomic, readonly) NSString *subtreeValidationResultSummary;

@property(nonatomic, readonly) NSMutableDictionary *memento;

@property(nonatomic, readonly) BOOL exposedToUser;  // if NO, container name will not be displayed
@property(nonatomic, readonly) NSString *title;
@property(nonatomic, readonly) NSArray *instances;
@property(nonatomic, strong) NSString *version;

- (void)validate;

// override points
- (RuntimeInstance *)newRuntimeInstanceWithData:(NSDictionary *)data;
- (void)doValidate;

// to be called by subclasses
- (void)setValid;
- (void)setInvalidWithError:(NSError *)error;
- (void)updateInstancesWithData:(NSArray *)instancesData;

- (void)didChange;

@end
