#import <Foundation/Foundation.h>

@import ATPathSpec;


@interface FSTreeFilter : NSObject {
    NSSet *_enabledExtensions;
    NSSet *_excludedNames;
    NSSet *_excludedPaths;
    BOOL _ignoreEmacsCraft;
    BOOL _ignoreHiddenFiles;
    ATPathSpec *_spec;
}

@property(nonatomic) BOOL ignoreHiddenFiles;
@property(nonatomic, copy) NSSet *enabledExtensions;
@property(nonatomic, copy) NSSet *excludedNames;
@property(nonatomic, copy) NSSet *excludedPaths;
@property(nonatomic, retain) ATPathSpec *spec;

- (BOOL)acceptsFileName:(NSString *)name isDirectory:(BOOL)isDirectory;
- (BOOL)acceptsFile:(NSString *)relativePath isDirectory:(BOOL)isDirectory;

@end
