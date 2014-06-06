
#include "console.h"
#include "stringutil.h"

#import "Compiler.h"
#import "Plugin.h"
#import "ToolOutput.h"
#import "Project.h"
#import "Runtimes.h"

#import "OldFSTree.h"
#import "RegexKitLite.h"
#import "NSTask+OneLineTasksWithOutput.h"
#import "NSArray+ATSubstitutions.h"
#import "ATFunctionalStyle.h"
#import "NSString+SmartRegexpCaptures.h"


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
        _uniqueId = [_name lowercaseString];
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


#pragma mark - Paths

- (NSArray *)pathsOfSourceFilesInTree:(FSTree *)tree {
    NSSet *validExtensions = [NSSet setWithArray:_extensions];
    return [tree pathsOfFilesMatching:^BOOL(NSString *name) {
        return [validExtensions containsObject:[name pathExtension]];
    }];
}


#pragma mark - Import Support

- (NSSet *)referencedPathFragmentsForPath:(NSString *)path {
    if ([_importRegExps count] == 0)
        return [NSSet set];

    NSError *error = nil;
    NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (!text) {
        NSLog(@"Failed to read '%@' for determining imports. Error: %@", path, [error localizedDescription]);
        return [NSSet set];
    }

    NSMutableSet *result = [NSMutableSet set];

    void (^processImport)(NSString *path) = ^(NSString *path){
        if ([_defaultImportedExts count] > 0 && [[path pathExtension] length] == 0) {
            for (NSString *ext in _defaultImportedExts) {
                NSString *newPath = [path stringByAppendingFormat:@".%@", ext];
                for (NSString *mapping in _importToFileMappings) {
                    NSString *dir = [newPath stringByDeletingLastPathComponent];
                    NSString *name = [newPath lastPathComponent];
                    NSString *mapped = [[mapping stringByReplacingOccurrencesOfString:@"$(file)" withString:name] stringByReplacingOccurrencesOfString:@"$(dir)" withString:dir];
                    if ([[mapped substringToIndex:2] isEqualToString:@"./"])
                        mapped = [mapped substringFromIndex:2];
                    [result addObject:mapped];
                }
            }
        } else if ([[path pathExtension] length] > 0 && [_nonImportedExts containsObject:[path pathExtension]]) {
            // do nothing; e.g. @import "foo.css" in LESS does not actually import the file
        } else {
            for (NSString *mapping in _importToFileMappings) {
                NSString *newPath = path;
                NSString *dir = [newPath stringByDeletingLastPathComponent];
                NSString *name = [newPath lastPathComponent];
                NSString *mapped = [[mapping stringByReplacingOccurrencesOfString:@"$(file)" withString:name] stringByReplacingOccurrencesOfString:@"$(dir)" withString:dir];
                if ([[mapped substringToIndex:2] isEqualToString:@"./"])
                    mapped = [mapped substringFromIndex:2];
                [result addObject:mapped];
            }
        }
    };

    for (NSString *regexp in _importRegExps) {
        [text enumerateStringsMatchedByRegex:regexp usingBlock:^(NSInteger captureCount, NSString *const __unsafe_unretained *capturedStrings, const NSRange *capturedRanges, volatile BOOL *const stop) {
            if (captureCount != 2) {
                NSLog(@"Skipping import regexp '%@' for compiler %@ because the regexp does not have exactly one capture group.", regexp, _name);
                return;
            }
            processImport(capturedStrings[1]);
            
            __block NSUInteger start = capturedRanges[0].location + capturedRanges[0].length;
            while (start < text.length) {
                __block BOOL found = NO;
                for (__strong NSString *contRegexp in _importContinuationRegExps) {
                    contRegexp = [@"^\\s*" stringByAppendingString:contRegexp];
                    [[text substringFromIndex:start] enumerateStringsMatchedByRegex:contRegexp usingBlock:^(NSInteger captureCount, NSString *const
                                                                                                            __unsafe_unretained *capturedStrings, const NSRange *capturedRanges, volatile BOOL *const stop) {
                        if (captureCount != 2) {
                            NSLog(@"Skipping import continuation regexp '%@' for compiler %@ because the regexp does not have exactly one capture group.", contRegexp, _name);
                            return;
                        }
                        processImport(capturedStrings[1]);
                        start += capturedRanges[0].location + capturedRanges[0].length;
                        *stop = found = YES;
                    }];
                    if (found)
                        break;
                }
                if (!found)
                    break;
            }
        }];
    }
    return result;
}

- (BOOL)usesExtension:(NSString *)extension {
    return [_extensions containsObject:extension];
}

@end
