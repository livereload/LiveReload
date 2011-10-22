
#import <Foundation/Foundation.h>


@class Compiler;
@class CompilerVersion;
@class FileCompilationOptions;
@class Bag;


extern NSString *CompilationOptionsEnabledChangedNotification;


typedef enum {
//    CompilationModeIgnore,
    CompilationModeDisabled,
    CompilationModeCompile,
    CompilationModeMiddleware,
} CompilationMode;


@interface CompilationOptions : NSObject {
@private
    Compiler              *_compiler;
    Bag                   *_globalOptions;
    NSArray               *_includeDirectories;
    NSMutableDictionary   *_fileOptions; // NSString to FileCompilationOptions
    NSString              *_additionalArguments;
    CompilationMode        _mode;

    NSArray               *_availableVersions;
    CompilerVersion       *_version;
}

- (id)initWithCompiler:(Compiler *)compiler memento:(NSDictionary *)memento;

@property(nonatomic, readonly) Compiler *compiler;

- (NSDictionary *)memento;

@property(nonatomic) CompilationMode mode;
@property(nonatomic, readonly) NSString *modeDisplayName;
@property (nonatomic, readonly, getter = isCompileModeActive) BOOL compileModeActive;

@property(nonatomic, readonly) NSArray *availableVersions;
@property(nonatomic, retain) CompilerVersion *version;

@property(nonatomic, readonly) Bag *globalOptions;
@property(nonatomic, copy) NSString *additionalArguments;

- (FileCompilationOptions *)optionsForFileAtPath:(NSString *)path create:(BOOL)create;

@property(nonatomic, readonly) NSArray *allFileOptions;

@end
