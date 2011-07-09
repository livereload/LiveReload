
#import <Foundation/Foundation.h>


@class Compiler;
@class CompilerVersion;
@class FileCompilationOptions;


extern NSString *CompilationOptionsEnabledChangedNotification;


@interface CompilationOptions : NSObject {
@private
    Compiler              *_compiler;
    BOOL                   _enabled;
    NSMutableDictionary   *_globalOptions;
    NSArray               *_includeDirectories;
    NSMutableDictionary   *_fileOptions; // NSString to FileCompilationOptions

    NSArray               *_availableVersions;
    CompilerVersion       *_version;
}

- (id)initWithCompiler:(Compiler *)compiler dictionary:(NSDictionary *)info;

@property(nonatomic, readonly) Compiler *compiler;

@property(nonatomic) BOOL enabled;

@property(nonatomic, readonly) NSArray *availableVersions;
@property(nonatomic, retain) CompilerVersion *version;

@property(nonatomic, readonly) NSMutableDictionary *globalOptions;

- (FileCompilationOptions *)optionsForFileAtPath:(NSString *)path create:(BOOL)create;

@end
