
#import <Foundation/Foundation.h>


extern NSString *const LRRuntimeContainerDidChangeNotification;


@interface NRuntimeContainer : NSObject

- (id)initWithDictionary:(NSDictionary *)data;

@property(nonatomic, readonly) NSMutableDictionary *memento;

@property(nonatomic, readonly) BOOL exposedToUser;  // if NO, container name will not be displayed
@property(nonatomic, readonly) NSString *title;
@property(nonatomic, readonly) NSArray *instances;

- (void)validateAndDiscover;

- (void)didChange;

@end
