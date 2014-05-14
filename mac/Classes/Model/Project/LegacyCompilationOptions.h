
#import <Foundation/Foundation.h>


@class Compiler;
@class CompilerVersion;
@class LRFile;


@interface LegacyCompilationOptions : NSObject {
@private
    Compiler              *_compiler;
    NSMutableDictionary   *_globalOptions;
    NSArray               *_includeDirectories;
    NSMutableDictionary   *_fileOptions; // NSString to FileCompilationOptions
    NSString              *_additionalArguments;
    BOOL                   _enabled;

    NSArray               *_availableVersions;
    CompilerVersion       *_version;
}

- (id)initWithCompiler:(Compiler *)compiler memento:(NSDictionary *)memento;

@property(nonatomic, readonly) Compiler *compiler;

- (NSDictionary *)memento;

@property(nonatomic, getter=isEnabled) BOOL enabled;
@property(nonatomic, readonly, getter=isActive) BOOL active; // YES if enabled or not optional

@property(nonatomic, copy) NSString *additionalArguments;

- (id)valueForOptionIdentifier:(NSString *)optionIdentifier;
- (void)setValue:(id)value forOptionIdentifier:(NSString *)optionIdentifier;

@end
