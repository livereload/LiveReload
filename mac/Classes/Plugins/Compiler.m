
#include "console.h"
#include "stringutil.h"

#import "Compiler.h"
#import "Plugin.h"
#import "CompilationOptions.h"
#import "ToolOutput.h"
#import "Project.h"
#import "Runtimes.h"
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


#pragma mark - Compilation

- (void)compile:(NSString *)sourceRelPath into:(NSString *)destinationRelPath under:(NSString *)rootPath inProject:(Project *)project with:(CompilationOptions *)options compilerOutput:(ToolOutput **)compilerOutput {
    if (compilerOutput) *compilerOutput = nil;

    // TODO: move this into a more appropriate place
    setenv("COMPASS_FULL_SASS_BACKTRACE", "1", 1);

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSString *sourcePath = [rootPath stringByAppendingPathComponent:sourceRelPath];
    NSString *destinationPath = [rootPath stringByAppendingPathComponent:destinationRelPath];

    RuntimeInstance *rubyInstance = [[OldRubyManager sharedRubyManager] instanceIdentifiedBy:project.rubyVersionIdentifier];
    NSString *rubyPath = (rubyInstance.valid ? rubyInstance.executablePath : @"__!RUBY_NOT_FOUND!__");

    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 rubyPath, @"$(ruby)",
                                 [[NSBundle mainBundle] pathForResource:@"LiveReloadNodejs" ofType:nil], @"$(node)",
                                 _plugin.path, @"$(plugin)",
                                 rootPath, @"$(project_dir)",

                                 [sourcePath lastPathComponent], @"$(src_file)",
                                 sourcePath, @"$(src_path)",
                                 [sourcePath stringByDeletingLastPathComponent], @"$(src_dir)",
                                 sourceRelPath, @"$(src_rel_path)",

                                 [destinationPath lastPathComponent], @"$(dst_file)",
                                 destinationPath, @"$(dst_path)",
                                 destinationRelPath, @"$(dst_rel_path)",
                                 [destinationPath stringByDeletingLastPathComponent], @"$(dst_dir)",
                                 nil];

    NSString *additionalArguments = [options.additionalArguments stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSMutableArray *additionalArgumentsArray = [NSMutableArray array];

    for (ToolOption *toolOption in [self optionsForProject:project]) {
        [additionalArgumentsArray addObjectsFromArray:toolOption.currentCompilerArguments];
    }

    if ([additionalArguments length]) {
        [additionalArgumentsArray addObjectsFromArray:[additionalArguments componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    }
    [info setObject:[additionalArgumentsArray arrayBySubstitutingValuesFromDictionary:info] forKey:@"$(additional)"];

    NSArray *arguments = [_commandLine arrayBySubstitutingValuesFromDictionary:info];
    NSLog(@"Running compiler: %@", [arguments description]);

    NSString *runDirectory;
    if (_runDirectory) {
        runDirectory = [_runDirectory stringBySubstitutingValuesFromDictionary:info];
    } else {
        runDirectory = NSTemporaryDirectory();
    }

    BOOL rubyInUse = [[arguments componentsJoinedByString:@" "] rangeOfString:rubyPath].length > 0;
    if (rubyInUse && !rubyInstance.valid) {
        NSLog(@"Ruby version '%@' does not exist, refusing to run.", project.rubyVersionIdentifier);
        *compilerOutput = [[ToolOutput alloc] initWithCompiler:self type:ToolOutputTypeError sourcePath:sourcePath line:0 message:@"Ruby not found. Please visit this project's compiler settings and choose another Ruby interpreter" output:@""];
        return;
    }

    NSString *commandLine = [arguments componentsJoinedByString:@" "]; // stringByReplacingOccurrencesOfString:[[NSBundle mainBundle] resourcePath] withString:@"$LiveReloadResources"] stringByReplacingOccurrencesOfString:[@"~" stringByExpandingTildeInPath] withString:@"~"];
    NSString *command = [arguments objectAtIndex:0];
    arguments = [arguments subarrayWithRange:NSMakeRange(1, [arguments count] - 1)];

    NSError *error = nil;
    NSString *pwd = [[NSFileManager defaultManager] currentDirectoryPath];
    [[NSFileManager defaultManager] changeCurrentDirectoryPath:runDirectory];
    NSString *output = [NSTask stringByLaunchingPath:command
                                       withArguments:arguments
                                               error:&error];
    [[NSFileManager defaultManager] changeCurrentDirectoryPath:pwd];

    NSString *strippedOutput = [output stringByReplacingOccurrencesOfRegex:@"(\\e\\[.*?m)+" withString:@"<ESC>"];
    NSString *cleanOutput = [[strippedOutput stringByReplacingOccurrencesOfRegex:@"<ESC>" withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (cleanOutput.length > 0) {
        const char *project_path = [project.path UTF8String];
        console_printf("\n%s compiler:\n%s\n\n%s\n\n", [self.name UTF8String], str_collapse_paths([commandLine UTF8String], project_path), str_collapse_paths([cleanOutput UTF8String], project_path));
    }

    if (error) {
        NSLog(@"Error: %@\nOutput:\n%@", [error description], strippedOutput);
        if ([error code] == kNSTaskProcessOutputError) {
            NSDictionary *substitutions = [NSDictionary dictionaryWithObjectsAndKeys:
                                           @"[^\\n]+?", @"file",
                                           @"\\d+", @"line",
                                           @"\\S[^\\n]+?", @"message",
                                           nil];

            NSDictionary *data = nil;
            for (id regexp in _errorFormats) {
                // regexp is either a string or a dictionary

                // TODO: handle dictionaries like { "pattern": "^TypeError: ", "message": "Internal LESS compiler error" },
                if (![regexp respondsToSelector:@selector(rangeOfString:)])
                    continue;

                if ([regexp rangeOfString:@"message-override"].location != NSNotFound || [regexp rangeOfString:@"***"].location != NSNotFound)
                    continue;  // new Node.js features not supported by this native code (yet?)

                NSString *stripped;
                if ([regexp rangeOfString:@"<ESC>"].length > 0) {
                    stripped = strippedOutput;
                } else {
                    stripped = [output stringByReplacingOccurrencesOfRegex:@"(\\e\\[.*?m)+" withString:@""];
                }
                NSDictionary *match = [stripped dictionaryByMatchingWithRegexp:regexp withSmartSubstitutions:substitutions options:0];
                if ([match count] > [data count]) {
                    data = match;
                }
            }

            NSString *file = [data objectForKey:@"file"];
            NSString *line = [data objectForKey:@"line"];
            NSString *message = [[data objectForKey:@"message"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            enum ToolOutputType errorType = (message ? ToolOutputTypeError : ToolOutputTypeErrorRaw);

            if (!file) {
                file = sourcePath;
            } else if (![file isAbsolutePath]) {
                // used by Compass
                NSString *candidate1 = [rootPath stringByAppendingPathComponent:file];
                // used by everyone else
                NSString *candidate2 = [[sourcePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:file];
                if ([[NSFileManager defaultManager] fileExistsAtPath:candidate2]) {
                    file = candidate2;
                } else if ([[NSFileManager defaultManager] fileExistsAtPath:candidate1]) {
                    file = candidate1;
                }
            }
            if (errorType == ToolOutputTypeErrorRaw) {
                message = output;
                if ([message length] == 0) {
                    message = @"Compilation failed with an empty output.";
                }
                console_printf("%s: compilation failed.", [[sourcePath lastPathComponent] UTF8String]);
            } else {
                if (line.length > 0) {
                    console_printf("%s(%s): %s", [[sourcePath lastPathComponent] UTF8String], [line UTF8String], [message UTF8String]);
                } else {
                    console_printf("%s: %s", [[sourcePath lastPathComponent] UTF8String], [message UTF8String]);
                }
            }

            if (compilerOutput) {
                NSInteger lineNo = [line integerValue];
                *compilerOutput = [[ToolOutput alloc] initWithCompiler:self type:errorType sourcePath:file line:lineNo message:message output:cleanOutput] ;
            }
        }
    } else {
        NSLog(@"Output:\n%@", strippedOutput);
        console_printf("%s compiled.", [[sourcePath lastPathComponent] UTF8String]);
    }
    [pool drain];

    //compilerOutput returned by reference and must be autoreleased, but not in local pool
    [*compilerOutput autorelease];
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
        [text enumerateStringsMatchedByRegex:regexp usingBlock:^(NSInteger captureCount, NSString *const *capturedStrings, const NSRange *capturedRanges, volatile BOOL *const stop) {
            if (captureCount != 2) {
                NSLog(@"Skipping import regexp '%@' for compiler %@ because the regexp does not have exactly one capture group.", regexp, _name);
                return;
            }
            processImport(capturedStrings[1]);
            
            __block NSUInteger start = capturedRanges[0].location + capturedRanges[0].length;
            while (start < text.length) {
                __block BOOL found = NO;
                for (NSString *contRegexp in _importContinuationRegExps) {
                    contRegexp = [@"^\\s*" stringByAppendingString:contRegexp];
                    [[text substringFromIndex:start] enumerateStringsMatchedByRegex:contRegexp usingBlock:^(NSInteger captureCount, NSString *const *capturedStrings, const NSRange *capturedRanges, volatile BOOL *const stop) {
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
