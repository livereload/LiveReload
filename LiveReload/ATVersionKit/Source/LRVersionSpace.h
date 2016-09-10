
#import <Foundation/Foundation.h>


@class LRVersion;
@class LRVersionSet;


NS_ASSUME_NONNULL_BEGIN

@interface LRVersionSpace : NSObject

- (LRVersion *)versionWithString:(NSString *)string;

- (LRVersionSet *)versionSetWithString:(NSString *)string;

- (LRVersion *)versionWithMajor:(NSInteger)major minor:(NSInteger)minor;

@end

NS_ASSUME_NONNULL_END
