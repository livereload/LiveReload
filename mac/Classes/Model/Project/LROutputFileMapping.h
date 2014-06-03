
#import <Foundation/Foundation.h>


@interface LROutputFileMapping : NSObject

- (instancetype)initWithSubfolder:(NSString *)subfolder recursive:(BOOL)recursive mask:(NSString *)mask;

@property(nonatomic, readonly) NSString *subfolder;
@property(nonatomic, readonly) BOOL recursive;  // defaults to YES
@property(nonatomic, readonly) NSString *mask;

@end
