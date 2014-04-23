
#import "LROption.h"


@interface LROutputMappingOption : LROption

@property(nonatomic, copy) NSString *subfolder;
@property(nonatomic) BOOL recursive;
@property(nonatomic, copy) NSString *mask;

@property(nonatomic, readonly, copy) NSArray *availableSubfolders;

@end
