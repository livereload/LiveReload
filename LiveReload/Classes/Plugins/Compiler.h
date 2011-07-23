
#import <Foundation/Foundation.h>


@class Plugin;
@class CompilationOptions;
@class FSTree;
@class ToolError;


@interface Compiler : NSObject {
@private
    __weak Plugin    *_plugin;
    NSString         *_uniqueId;
    NSString         *_name;
    NSArray          *_commandLine;
    NSString         *_runDirectory;
    BOOL              _needsOutputDirectory;
    NSArray          *_extensions;
    NSString         *_destinationExtension;
    NSArray          *_errorFormats;
    NSArray          *_expectedOutputDirectoryNames;
}

- (id)initWithDictionary:(NSDictionary *)info plugin:(Plugin *)plugin;

@property(nonatomic, readonly) NSString *uniqueId;
@property(nonatomic, readonly) NSString *name;
@property(nonatomic, readonly) NSArray *extensions;
@property(nonatomic, readonly) NSString *destinationExtension;
@property(nonatomic, readonly) NSArray *expectedOutputDirectoryNames;
@property(nonatomic, readonly) BOOL needsOutputDirectory;

@property(nonatomic, readonly) NSString *sourceExtensionsForDisplay;
@property(nonatomic, readonly) NSString *destinationExtensionForDisplay;

- (NSString *)derivedNameForFile:(NSString *)path;

- (void)compile:(NSString *)sourceRelPath into:(NSString *)destinationRelPath under:(NSString *)rootPath with:(CompilationOptions *)options compilerError:(ToolError **)compilerError;

- (NSArray *)pathsOfSourceFilesInTree:(FSTree *)tree;

@end
