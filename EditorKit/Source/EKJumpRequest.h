
#import <Foundation/Foundation.h>


enum {
    EKJumpRequestValueUnknown = -1
};


@interface EKJumpRequest : NSObject

- (id)initWithFileURL:(NSURL *)fileURL line:(int)line column:(int)column;

@property(nonatomic, strong) NSURL *fileURL;
@property(nonatomic, assign) int line;
@property(nonatomic, assign) int column;

- (NSString *)componentsJoinedByString:(NSString *)separator;

- (int)computeLinearOffsetWithError:(NSError **)outError;

@end
