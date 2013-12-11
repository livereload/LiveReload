
#import <Foundation/Foundation.h>


@interface LRTest : NSObject

- (id)initWithFolderURL:(NSURL *)folderURL;

@property(nonatomic, readonly) BOOL valid;

- (void)run;
@property(nonatomic, strong) dispatch_block_t completionBlock;
@property(nonatomic, readonly) NSError *error;
@property(nonatomic, readonly) BOOL succeeded;

@end
