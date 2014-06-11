
#import "LRPathProcessing.h"
#import "ATPathSpec.h"


NSString *LRDeriveDestinationFileName(NSString *sourceFileName, NSString *destinationNameMask, ATPathSpec *sourcePathSpec) {
    NSString *sourceBaseName = nil;

    // source spec introspection required to handle extensions like ".coffee.md"
    NSDictionary *matchInfo = [sourcePathSpec matchInfoForPath:sourceFileName type:ATPathSpecEntryTypeFile];
    if (matchInfo) {
        NSString *suffix = matchInfo[ATPathSpecMatchInfoMatchedSuffix];
        if (suffix && [sourceFileName hasSuffix:suffix]) {
            NSRange range = [sourceFileName rangeOfString:suffix options:NSBackwardsSearch];
            sourceBaseName = [sourceFileName substringToIndex:range.location];
        }
    }

    if (!sourceBaseName) {
        sourceBaseName = [sourceFileName stringByDeletingPathExtension];
    }

    // handle a mask like "*.php" applied to a source file named like "foo.php.jade"
    while ([destinationNameMask pathExtension].length > 0 && [sourceBaseName pathExtension].length > 0 && [[destinationNameMask pathExtension] isEqualToString:[sourceBaseName pathExtension]]) {
        destinationNameMask = [destinationNameMask stringByDeletingPathExtension];
    }

    return [destinationNameMask stringByReplacingOccurrencesOfString:@"*" withString:sourceBaseName];
}
