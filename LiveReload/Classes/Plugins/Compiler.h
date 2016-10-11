//
//#import <Foundation/Foundation.h>
//
//
//@class Plugin;
//@class ActionOptions;
//@class FileCompilationOptions;
//@class FSTree;
//@class ToolOutput;
//@class Project;
//
//
//@interface Compiler : NSObject {
//@private
//    /*__weak*/ Plugin    *_plugin;
//    NSString         *_uniqueId;
//    NSString         *_name;
//    NSArray          *_commandLine;
//    NSString         *_runDirectory;
//    BOOL              _needsOutputDirectory;
//    BOOL              _optional;
//    NSArray          *_extensions;
//    NSString         *_destinationExtension;
//    NSArray          *_errorFormats;
//    NSArray          *_expectedOutputDirectoryNames;
//
//    NSArray          *_importRegExps;
//    NSArray          *_importContinuationRegExps;
//    NSArray          *_defaultImportedExts;
//    NSArray          *_nonImportedExts;
//    NSArray          *_importToFileMappings;
//
//    NSArray          *_options;
//
//    NSArray          *_excludedSuffixes;
//}
//
//- (id)initWithDictionary:(NSDictionary *)info plugin:(Plugin *)plugin;
//
//@property(nonatomic, readonly) NSString *uniqueId;
//@property(nonatomic, readonly) NSString *name;
//@property(nonatomic, readonly) NSArray *extensions;
//@property(nonatomic, readonly) NSString *destinationExtension;
//@property(nonatomic, readonly) NSArray *expectedOutputDirectoryNames;
//@property(nonatomic, readonly) BOOL needsOutputDirectory;
//@property(nonatomic, readonly, getter=isOptional) BOOL optional;
//
//@property(nonatomic, readonly) NSString *sourceExtensionsForDisplay;
//@property(nonatomic, readonly) NSString *destinationExtensionForDisplay;
//
//@property(nonatomic, readonly) NSArray *options;
//- (NSArray *)optionsForProject:(Project *)project;
//
//- (void)compile:(NSString *)sourceRelPath into:(NSString *)destinationRelPath under:(NSString *)rootPath inProject:(Project *)project with:(ActionOptions *)options compilerOutput:(ToolOutput **)compilerOutput;
//
//- (NSArray *)pathsOfSourceFilesInTree:(FSTree *)tree;
//- (BOOL)canCompileFileNamed:(NSString *)fileNameOrPath extension:(NSString *)extension;
//
//- (NSSet *)referencedPathFragmentsForPath:(NSString *)path;
//
//@end
