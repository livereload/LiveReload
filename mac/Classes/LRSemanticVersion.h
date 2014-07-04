
#import "LRVersion.h"


@interface LRSemanticVersion : LRVersion

- (id)initWithMajor:(NSInteger)major minor:(NSInteger)minor patch:(NSInteger)patch prereleaseComponents:(NSArray *)prereleaseComponents build:(NSString *)build error:(NSError *)error;

@property (nonatomic, readonly) NSInteger major;
@property (nonatomic, readonly) NSInteger minor;
@property (nonatomic, readonly) NSInteger patch;

@property (nonatomic, readonly) NSString *prerelease;
@property (nonatomic, readonly) NSString *build;

@property (nonatomic, readonly) NSArray *prereleaseComponents;

+ (instancetype)semanticVersionWithString:(NSString *)string;

@end
