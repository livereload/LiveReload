
#import <Foundation/Foundation.h>


@class Compiler;
@class CompilerVersion;


@interface CompilationOptions : NSObject {
@private
    Compiler              *_compiler;
    BOOL                   _enabled;
    NSMutableDictionary   *_globalOptions;
    NSArray               *_includeDirectories;
    NSDictionary          *_fileOptions; // dictionary of dictionaries

    NSArray               *_availableVersions;
    CompilerVersion       *_version;
}

- (id)initWithCompiler:(Compiler *)compiler dictionary:(NSDictionary *)info;

@property(nonatomic, readonly) Compiler *compiler;

@property(nonatomic) BOOL enabled;

@property(nonatomic, readonly) NSArray *availableVersions;
@property(nonatomic, retain) CompilerVersion *version;

@property(nonatomic, readonly) NSMutableDictionary *globalOptions;

@end
