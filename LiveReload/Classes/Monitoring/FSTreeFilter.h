
#import <Foundation/Foundation.h>


@interface FSTreeFilter : NSObject {
    NSSet *_enabledExtensions;
    NSSet *_excludedNames;
    BOOL _ignoreHiddenFiles;
}

@property(nonatomic) BOOL ignoreHiddenFiles;
@property(nonatomic, copy) NSSet *enabledExtensions;
@property(nonatomic, copy) NSSet *excludedNames;

- (BOOL)acceptsFileName:(NSString *)name isDirectory:(BOOL)isDirectory;

@end
