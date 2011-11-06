
#import <Foundation/Foundation.h>


@class Plugin;
@class CompilationOptions;
@class FSTree;
@class ToolOutput;


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

    NSArray          *_importRegExps;
    NSArray          *_defaultImportedExts;
    NSArray          *_nonImportedExts;
    NSArray          *_importToFileMappings;

    NSArray          *_options;
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

@property(nonatomic, readonly) NSArray *options;

- (NSString *)derivedNameForFile:(NSString *)path;

- (void)compile:(NSString *)sourceRelPath into:(NSString *)destinationRelPath under:(NSString *)rootPath with:(CompilationOptions *)options compilerOutput:(ToolOutput **)compilerOutput;

- (NSArray *)pathsOfSourceFilesInTree:(FSTree *)tree;

- (NSSet *)referencedPathFragmentsForPath:(NSString *)path;

@end
