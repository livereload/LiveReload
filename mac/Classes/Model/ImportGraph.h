
#import <Foundation/Foundation.h>

@interface ImportGraph : NSObject {
    NSMutableDictionary   *_filesToNodes;
}

- (void)setRereferencedPaths:(NSSet *)referencedPaths forPath:(NSString *)path;
- (void)removePath:(NSString *)path collectingPathsToRecomputeInto:(NSMutableSet *)pathsToRecompute;
- (void)removeAllPaths;

- (NSSet *)rootReferencingPathsForPath:(NSString *)path;
- (BOOL)hasReferencingPathsForPath:(NSString *)path;

@end


@interface ImportGraphNode : NSObject {
@public
    NSString              *_path;
    NSMutableSet          *_referencedPaths;
    NSMutableSet          *_referencingPaths;
}

- (id)initWithPath:(NSString *)path;

- (BOOL)isNotEmpty;

@end
