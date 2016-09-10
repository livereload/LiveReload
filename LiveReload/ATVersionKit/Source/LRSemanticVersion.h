#import "LRVersion.h"


NS_ASSUME_NONNULL_BEGIN

@interface LRSemanticVersion : LRVersion

- (id)initWithMajor:(NSInteger)major minor:(NSInteger)minor patch:(NSInteger)patch prereleaseComponents:(NSArray *)prereleaseComponents build:(NSString *)build error:(nullable NSError *)error;

@property (nonatomic, readonly) NSInteger major;
@property (nonatomic, readonly) NSInteger minor;
@property (nonatomic, readonly) NSInteger patch;

@property (nonatomic, readonly) NSString *prerelease;
@property (nonatomic, readonly) NSString *build;

@property (nonatomic, readonly) NSArray<NSString *> *prereleaseComponents;

+ (instancetype)semanticVersionWithString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
