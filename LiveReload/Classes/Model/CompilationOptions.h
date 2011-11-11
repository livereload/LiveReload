
#import <Foundation/Foundation.h>


@class Compiler;
@class CompilerVersion;
@class FileCompilationOptions;


@interface CompilationOptions : NSObject {
@private
    Compiler              *_compiler;
    NSMutableDictionary   *_globalOptions;
    NSArray               *_includeDirectories;
    NSMutableDictionary   *_fileOptions; // NSString to FileCompilationOptions
    NSString              *_additionalArguments;

    NSArray               *_availableVersions;
    CompilerVersion       *_version;
}

- (id)initWithCompiler:(Compiler *)compiler memento:(NSDictionary *)memento;

@property(nonatomic, readonly) Compiler *compiler;

- (NSDictionary *)memento;

@property(nonatomic, readonly) NSArray *availableVersions;
@property(nonatomic, retain) CompilerVersion *version;

@property(nonatomic, copy) NSString *additionalArguments;

- (FileCompilationOptions *)optionsForFileAtPath:(NSString *)path create:(BOOL)create;

@property(nonatomic, readonly) NSArray *allFileOptions;

- (id)valueForOptionIdentifier:(NSString *)optionIdentifier;
- (void)setValue:(id)value forOptionIdentifier:(NSString *)optionIdentifier;

@end
