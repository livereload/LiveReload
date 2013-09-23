
#import <Foundation/Foundation.h>

NSComparisonResult GlitterCompareVersions(NSString *lhs, NSString *rhs);
BOOL GlitterMatchVersionRange(NSString *range, NSString *ver);
void GlitterVersionComparisonSelfTest();
