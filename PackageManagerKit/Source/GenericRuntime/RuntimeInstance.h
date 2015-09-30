
#import <Foundation/Foundation.h>
#import "RuntimeObject.h"


extern NSString *const LRRuntimeInstanceDidChangeNotification;


@class LRPackageContainer;


@interface RuntimeInstance : NSObject <RuntimeObject>

- (id)initWithMemento:(NSDictionary *)memento additionalInfo:(NSDictionary *)additionalInfo;
@property(nonatomic, readonly) NSMutableDictionary *memento;

@property(nonatomic, readonly, getter=isPersistent) BOOL persistent;

@property(nonatomic, strong) NSString *identifier;
@property(nonatomic, readonly) NSURL *executableURL;  // override point
@property(nonatomic, readonly) NSString *executablePath;
@property(nonatomic, readonly) NSString *basicTitle;  // override point; "System Ruby", "RVM Ruby"

@property(nonatomic, assign) BOOL validationInProgress;
@property(nonatomic, assign) BOOL validationPerformed;
@property(nonatomic, assign) BOOL valid;
@property(nonatomic, strong) NSString *version;

@property(nonatomic, readonly) NSString *statusQualifier;
@property(nonatomic, readonly) NSString *title;

@property(nonatomic, readonly) NSArray *defaultPackageContainers;

- (NSArray *)launchArgumentsWithAdditionalRuntimeContainers:(NSArray *)additionalRuntimeContainers environment:(NSMutableDictionary *)environment;

- (void)validate;

- (void)doValidate; // override point, must call one of the methods below
- (void)validationSucceededWithData:(NSDictionary *)data;
- (void)validationFailedWithError:(NSError *)error;

//@property(nonatomic, readonly) NSArray *librarySets;

- (void)didChange;

@end
