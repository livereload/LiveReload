
#import <Foundation/Foundation.h>


typedef enum {
    LRTestOptionNone = 0,
    LRTestOptionLegacy = 0x01,
} LRTestOptions;


@interface LRSelfTest : NSObject

- (id)initWithFolderURL:(NSURL *)folderURL options:(LRTestOptions)options;

@property(nonatomic, readonly) BOOL valid;

- (void)run;
@property(nonatomic, strong) dispatch_block_t completionBlock;
@property(nonatomic, readonly) NSError *error;
@property(nonatomic, readonly) BOOL succeeded;

@end
