
#import <Foundation/Foundation.h>


@class Compiler;
@class FileCompilationOptions;


@interface ActionOptions : NSObject {
@private
    NSString              *_actionIdentifier;
    NSMutableDictionary   *_globalOptions;
    NSArray               *_includeDirectories;
    NSMutableDictionary   *_fileOptions; // NSString to FileCompilationOptions
    NSString              *_additionalArguments;
    BOOL                   _enabled;

    NSArray               *_availableVersions;
}

- (id)initWithActionIdentifier:(NSString *)actionIdentifier memento:(NSDictionary *)memento;

- (NSDictionary *)memento;

@property(nonatomic, readonly) NSArray *availableVersions;

@property(nonatomic, getter=isEnabled) BOOL enabled;
@property(nonatomic, readonly, getter=isActive) BOOL active; // YES if enabled or not optional

@property(nonatomic, copy) NSString *additionalArguments;

- (FileCompilationOptions *)optionsForFileAtPath:(NSString *)path create:(BOOL)create;

- (NSString *)sourcePathThatCompilesInto:(NSString *)outputPath;

@property(nonatomic, readonly) NSArray *allFileOptions;

- (id)valueForOptionIdentifier:(NSString *)optionIdentifier;
- (void)setValue:(id)value forOptionIdentifier:(NSString *)optionIdentifier;

@end
