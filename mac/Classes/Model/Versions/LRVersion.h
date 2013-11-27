
#import <Foundation/Foundation.h>


@class LRVersionSpace;


extern NSString *const LRVersionErrorDomain;
typedef enum {
    LRVersionErrorCodeNone,
    LRVersionErrorCodeInvalidVersionNumber,
    LRVersionErrorCodeInvalidExtraVersionNumber,
    LRVersionErrorCodeInvalidPrereleaseComponent,
    LRVersionErrorCodeInvalidRangeSpec,
} LRVersionErrorCode;


@interface LRVersion : NSObject

- (id)initWithVersionSpace:(LRVersionSpace *)versionSpace error:(NSError *)error;

@property(nonatomic, readonly) LRVersionSpace *versionSpace;

@property(nonatomic, readonly, getter=isValid) BOOL valid;
@property(nonatomic, readonly) NSError *error;

@property (nonatomic, readonly) NSInteger major;
@property (nonatomic, readonly) NSInteger minor;

- (NSComparisonResult)compare:(LRVersion *)aVersion; // override point

@end
