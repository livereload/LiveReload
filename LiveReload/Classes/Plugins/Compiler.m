
#import "Compiler.h"
#import "Plugin.h"
#import "CompilationOptions.h"
#import "ToolOutput.h"

#import "FSTree.h"
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

- (NSString *)derivedNameForFile:(NSString *)path {
    NSString *bareName = [[path lastPathComponent] stringByDeletingPathExtension];
    if ([[bareName pathExtension] isEqualToString:self.destinationExtension]) {
        // handle names like style.css.sass
        return bareName;
    }
    return [bareName stringByAppendingPathExtension:self.destinationExtension];
}

- (NSArray *)pathsOfSourceFilesInTree:(FSTree *)tree {
    NSSet *validExtensions = [NSSet setWithArray:_extensions];
    return [tree pathsOfFilesMatching:^BOOL(NSString *name) {
        return [validExtensions containsObject:[name pathExtension]];
    }];
}


#pragma mark - Compilation

- (void)compile:(NSString *)sourceRelPath into:(NSString *)destinationRelPath under:(NSString *)rootPath with:(CompilationOptions *)options compilerOutput:(ToolOutput **)compilerOutput {
    if (compilerOutput) *compilerOutput = nil;

    NSString *sourcePath = [rootPath stringByAppendingPathComponent:sourceRelPath];
    NSString *destinationPath = [rootPath stringByAppendingPathComponent:destinationRelPath];

    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 @"/System/Library/Frameworks/Ruby.framework/Versions/Current/usr/bin/ruby", @"$(ruby)",
                                 [[NSBundle mainBundle] pathForResource:@"node" ofType:nil], @"$(node)",
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
    NSArray *additionalArgumentsArray = [NSArray array];
    if ([additionalArguments length]) {
        additionalArgumentsArray = [[additionalArguments componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] arrayBySubstitutingValuesFromDictionary:info];
    }
    [info setObject:additionalArgumentsArray forKey:@"$(additional)"];

    NSArray *arguments = [_commandLine arrayBySubstitutingValuesFromDictionary:info];
    NSLog(@"Running compiler: %@", [arguments description]);

    NSString *runDirectory;
    if (_runDirectory) {
        runDirectory = [_runDirectory stringBySubstitutingValuesFromDictionary:info];
    } else {
        runDirectory = NSTemporaryDirectory();
    }

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
    NSString *cleanOutput = [strippedOutput stringByReplacingOccurrencesOfRegex:@"<ESC>" withString:@""];

    if (error) {
        NSLog(@"Error: %@\nOutput:\n%@", [error description], strippedOutput);
        if ([error code] == kNSTaskProcessOutputError) {
            NSDictionary *substitutions = [NSDictionary dictionaryWithObjectsAndKeys:
                                           @"[^\\n]+?", @"file",
                                           @"\\d+", @"line",
                                           @"\\S[^\\n]+?", @"message",
                                           nil];

            NSDictionary *data = nil;
            for (NSString *regexp in _errorFormats) {
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
            }

            if (compilerOutput) {
                NSInteger lineNo = [line integerValue];
                *compilerOutput = [[[ToolOutput alloc] initWithCompiler:self type:errorType sourcePath:file line:lineNo message:message output:cleanOutput] autorelease];
            }
        }
    } else {
        NSLog(@"Output:\n%@", strippedOutput);
    }
}

@end
