
#import <Foundation/Foundation.h>


@class Plugin;
@class FSTree;

@interface Compiler : NSObject {
@private
    __weak Plugin    *_plugin;
    NSString         *_uniqueId;
    NSString         *_name;
    NSArray          *_commandLine;
    NSArray          *_extensions;
    NSString         *_destinationExtension;
    NSArray          *_errorFormats;
}

- (id)initWithDictionary:(NSDictionary *)info plugin:(Plugin *)plugin;

@property(nonatomic, readonly) NSString *uniqueId;
@property(nonatomic, readonly) NSString *name;
@property(nonatomic, readonly) NSArray *extensions;
@property(nonatomic, readonly) NSString *destinationExtension;

- (NSString *)derivedNameForFile:(NSString *)path;

- (void)compile:(NSString *)sourcePath into:(NSString *)destinationPath;

- (NSArray *)pathsOfSourceFilesInTree:(FSTree *)tree;

@end
