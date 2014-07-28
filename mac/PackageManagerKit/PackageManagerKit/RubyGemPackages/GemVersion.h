
@import PiiVersionKit;


@interface GemVersion : LRVersion

+ (instancetype)gemVersionWithString:(NSString *)string;
+ (instancetype)gemVersionWithSegments:(NSArray *)segments;

@property(nonatomic, readonly) NSString *canonicalString;

@end
