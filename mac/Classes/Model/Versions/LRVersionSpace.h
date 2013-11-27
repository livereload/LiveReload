
#import <Foundation/Foundation.h>


@class LRVersion;
@class LRVersionSet;


@interface LRVersionSpace : NSObject

- (LRVersion *)versionWithString:(NSString *)string;

- (LRVersionSet *)versionSetWithString:(NSString *)string;

- (LRVersion *)versionWithMajor:(NSInteger)major minor:(NSInteger)minor;

@end
