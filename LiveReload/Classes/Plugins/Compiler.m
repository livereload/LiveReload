
#include "console.h"
#include "stringutil.h"

#import "Compiler.h"
#import "Plugin.h"
#import "CompilationOptions.h"
#import "ToolOutput.h"
#import "Project.h"
#import "RubyVersion.h"
#import "ToolOptions.h"

#import "OldFSTree.h"
#import "RegexKitLite.h"
#import "NSTask+OneLineTasksWithOutput.h"
#import "NSArray+Substitutions.h"
#import "ATFunctionalStyle.h"

@interface NSString (SmartRegexpCaptures)

- (NSDictionary *)dictionaryByMatchingWithRegexp:(NSString *)regexp withSmartSubstitutions:(NSDictionary *)substitutions options:(RKLRegexOptions)options;

@end

@implementation NSString (SmartRegexpCaptures)

- (NSDictionary *)dictionaryByMatchingWithRegexp:(NSString *)regexp withSmartSubstitutions:(NSDictionary *)substitutions options:(RKLRegexOptions)options {

    int captureIndexes[100];
    NSString *captureNames[100];
    NSUInteger captureCount = 0;

    while (1) {
        NSRange minRange = NSMakeRange(NSNotFound, 0);
        NSString *minKey = nil;

        for (NSString *key in substitutions) {
            NSRange range = [regexp rangeOfString:[NSString stringWithFormat:@"((%@))", key]];
            if (range.length > 0) {
                if (minRange.location == NSNotFound || range.location < minRange.location) {
                    minRange = range;
                    minKey = key;
                }
            }
        }

        if (minRange.length == 0) {
            break;
        } else {
            NSString *value = [substitutions objectForKey:minKey];
            value = [NSString stringWithFormat:@"(%@)", value];
            regexp = [regexp stringByReplacingCharactersInRange:minRange withString:value];
            captureIndexes[captureCount] = captureCount + 1;
            captureNames[captureCount] = minKey;
            ++captureCount;
        }
    }

    NSLog(@"Matching output against regexp: %@", regexp);
    if ([self rangeOfRegex:regexp].length == 0) {
        return nil;
    }
    return [self dictionaryByMatchingRegex:regexp options:options range:NSMakeRange(0, [self length]) error:nil withKeys:captureNames forCaptures:captureIndexes count:captureCount];
}

@end


@implementation Compiler

@synthesize uniqueId=_uniqueId;
@synthesize name=_name;
@synthesize extensions=_extensions;
@synthesize destinationExtension=_destinationExtension;
@synthesize expectedOutputDirectoryNames=_expectedOutputDirectoryNames;
@synthesize needsOutputDirectory=_needsOutputDirectory;
@synthesize options=_options;
@synthesize optional=_optional;


#pragma mark - init/dealloc

- (id)initWithDictionary:(NSDictionary *)info plugin:(Plugin *)plugin {
    self = [super init];
    if (self) {
        id raw;
        _plugin = plugin;
        _name = [[info objectForKey:@"Name"] copy];
        _commandLine = [[info objectForKey:@"CommandLine"] copy];
        _runDirectory = [[info objectForKey:@"RunIn"] copy];
        _extensions = [[info objectForKey:@"Extensions"] copy];
        _destinationExtension = [[info objectForKey:@"DestinationExtension"] copy];
        if ((raw = [info objectForKey:@"NeedsOutputDirectory"])) {
            _needsOutputDirectory = [raw boolValue];
        } else {
            _needsOutputDirectory = YES;
        }
        _errorFormats = [[info objectForKey:@"Errors"] copy];
        _uniqueId = [[_name lowercaseString] retain];
        _expectedOutputDirectoryNames = [[info objectForKey:@"ExpectedOutputDirectories"] copy];
        if (_expectedOutputDirectoryNames == nil)
            _expectedOutputDirectoryNames = [[NSArray alloc] init];
        _importRegExps = [[info objectForKey:@"ImportRegExps"] copy];
        if (!_importRegExps)
            _importRegExps = [[NSArray alloc] init];
        _importContinuationRegExps = [[info objectForKey:@"ImportContinuationRegExps"] copy];
        if (!_importContinuationRegExps)
            _importContinuationRegExps = [[NSArray alloc] init];
        _defaultImportedExts = [[info objectForKey:@"DefaultImportedExts"] copy];
        if (!_defaultImportedExts)
            _defaultImportedExts = [[NSArray alloc] init];
        _nonImportedExts = [[info objectForKey:@"NonImportedExts"] copy];
        if (!_nonImportedExts)
            _nonImportedExts = [[NSArray alloc] init];
        _importToFileMappings = [[info objectForKey:@"ImportToFileMappings"] copy];
        if (!_importToFileMappings)
            _importToFileMappings = [[NSArray alloc] initWithObjects:@"$(dir)/$(file)", nil];
        _options = [[info objectForKey:@"Options"] copy];
        if (!_options)
            _options = [[NSArray alloc] init];
        _optional = [[info objectForKey:@"Optional"] boolValue];
    }
    return self;
}

- (void)dealloc {
    [_commandLine release], _commandLine = nil;
    _plugin = nil;
    [super dealloc];
}


#pragma mark - Computed properties

- (NSString *)sourceExtensionsForDisplay {
    return [[_extensions arrayByMappingElementsUsingBlock:^id(id value) {
        return [NSString stringWithFormat:@".%@", value];
    }] componentsJoinedByString:@"/"];
}

- (NSString *)destinationExtensionForDisplay {
    return [NSString stringWithFormat:@".%@", _destinationExtension];
}


#pragma mark - Paths

- (NSArray *)pathsOfSourceFilesInTree:(FSTree *)tree {
    NSSet *validExtensions = [NSSet setWithArray:_extensions];
    return [tree pathsOfFilesMatching:^BOOL(NSString *name) {
        return [validExtensions containsObject:[name pathExtension]];
    }];
}


#pragma mark - Options

- (NSArray *)optionsForProject:(Project *)project {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:_options.count];
    for (NSDictionary *optionInfo in _options) {
        ToolOption *option = [ToolOption toolOptionWithCompiler:self project:project optionInfo:optionInfo];
        if (option) {
            [result addObject:option];
        } else {
            NSLog(@"Unrecognized option type %@ for compiler %@", [optionInfo objectForKey:@"Type"], self.uniqueId);
        }
    }
    return [NSArray arrayWithArray:result];
}


@end
