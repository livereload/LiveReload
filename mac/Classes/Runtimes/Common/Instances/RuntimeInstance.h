
#import <Foundation/Foundation.h>
#import "RuntimeObject.h"


extern NSString *const LRRuntimeInstanceDidChangeNotification;


@interface RuntimeInstance : NSObject <RuntimeObject>

- (id)initWithMemento:(NSDictionary *)memento additionalInfo:(NSDictionary *)additionalInfo;
@property(nonatomic, readonly) NSMutableDictionary *memento;

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

- (void)validate;

- (void)doValidate; // override point, must call one of the methods below
- (void)validationSucceededWithData:(NSDictionary *)data;
- (void)validationFailedWithError:(NSError *)error;

//@property(nonatomic, readonly) NSArray *librarySets;

- (void)didChange;

@end
