
#import "LRPluginCommons.h"
#import "RegexKitLite.h"
#import "Errors.h"



@implementation NSDictionary (LRPluginCommons)

+ (NSDictionary *)LR_dictionaryWithContentsOfJSONFileURL:(NSURL *)fileURL error:(NSError **)outError {
    NSError *error = nil;
    NSData *raw = [NSData dataWithContentsOfURL:fileURL options:0 error:&error];
    if (!raw)
        return_error(nil, outError, error);

    id object = [NSJSONSerialization JSONObjectWithData:raw options:0 error:&error];
    if (!object)
        return_error(nil, outError, error);

    if (![object isKindOfClass:[NSDictionary class]])
        return_error(nil, outError, [NSError errorWithDomain:LRErrorDomain code:LRErrorJsonParsingError userInfo:nil]);

    return object;
}

@end


void LRSetDottedKey(NSMutableDictionary *dictionary, NSString *key, id value) {
    NSRange range = [key rangeOfString:@"."];
    if (range.location == NSNotFound) {
        dictionary[key] = value;
    } else {
        NSString *folderKey = [key substringToIndex:range.location];
        NSString *subkey = [key substringFromIndex:range.location + range.length];

        NSMutableDictionary *folder;
        id folderRaw = dictionary[folderKey];
        if ([folderRaw isKindOfClass:[NSMutableDictionary class]])
            folder = folderRaw;
        else if ([folderRaw isKindOfClass:[NSDictionary class]])
            dictionary[folderKey] = folder = [folderRaw mutableCopy];
        else
            dictionary[folderKey] = folder = [[NSMutableDictionary alloc] init];

        LRSetDottedKey(folder, subkey, value);
    }
}

NSDictionary *LRExtractMetadata(NSString *content) {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    [properties setValue:@"foo" forKeyPath:@"bar.boz"];
    [content enumerateStringsMatchedByRegex:@"^(?:[^a-z\\s]*)\\s*LR ([a-zA-Z0-9.-]+)\\s*:(.*)$" options:RKLMultiline|RKLCaseless inRange:NSMakeRange(0, NSUIntegerMax) error:nil enumerationOptions:0 usingBlock:^(NSInteger captureCount, NSString *const *capturedStrings, const NSRange *capturedRanges, volatile BOOL *const stop) {
        //        NSLog(@"Match: %@  :::  %@  :::  %@", capturedStrings[0], capturedStrings[1], capturedStrings[2]);
        NSString *key = [capturedStrings[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *value = [capturedStrings[2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        LRSetDottedKey(properties, key, value);
    }];

    return properties;
}

NSDictionary *LRExtractFileMetadata(NSURL *file) {
    NSError *error;
    NSString *content = [NSString stringWithContentsOfURL:file encoding:NSUTF8StringEncoding error:&error];
    if (!content) {
        NSLog(@"Failed to read file at %@", file);
        return nil;
    }

    return LRExtractMetadata(content);
}

NSDictionary *LRParseKeyValueOutput(NSString *output) {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];

    for (NSString *line in [output componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]) {
        NSArray *match = [line captureComponentsMatchedByRegex:@"^\\s*([a-zA-Z0-9-]+)\\s*:(.*)$"];
        if ([match count] > 0) {
            NSString *key = match[1];
            NSString *value = [match[2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            properties[key] = value;
        }
    }

    return properties;
}

NSArray *LRFindPluginsInFolder(NSURL *folder, NSArray *validApiValues) {
    NSFileManager *fm = [NSFileManager defaultManager];

    NSMutableArray *plugins = [NSMutableArray array];
    NSError *error;
    NSArray *contents = [fm contentsOfDirectoryAtURL:folder includingPropertiesForKeys:@[NSFileType] options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
    NSLog(@"LRFindPluginsInFolder(%@): %@", folder, contents);

    for (NSURL *item in contents) {
        NSDictionary *attrs = [item resourceValuesForKeys:@[NSURLIsRegularFileKey, NSURLIsSymbolicLinkKey, NSURLIsReadableKey, NSURLIsExecutableKey] error:nil];
        if ([attrs[NSURLIsRegularFileKey] boolValue] || [attrs[NSURLIsSymbolicLinkKey ] boolValue]) {
            NSDictionary *props = LRExtractFileMetadata(item);
            if (!props[@"api"]) {
                NSLog(@"LRFindPluginsInFolder: Not a plugin (missing LR api key): %@", item);
                continue;
            }
            if (![validApiValues containsObject:props[@"api"]]) {
                NSLog(@"LRFindPluginsInFolder: Unsupported api value '%@' in '%@', looking for api values: %@", props[@"api"], item, [validApiValues componentsJoinedByString:@", or "]);
                continue;
            }
            NSLog(@"LRFindPluginsInFolder: Props of %@: %@", item, props);

            [plugins addObject:[[SingleFilePlugin alloc] initWithScriptFileURL:item properties:props]];
        }
    }
    
    return plugins;
}



@implementation SingleFilePlugin

@synthesize scriptFileURL = _scriptFileURL;
@synthesize properties = _properties;

- (id)initWithScriptFileURL:(NSURL *)aScriptFileURL properties:(NSDictionary *)aProperties {
    self = [super init];
    if (self) {
        _scriptFileURL = [aScriptFileURL copy];
        _properties = [aProperties copy];
    }
    return self;
}

- (id)invokeWithArguments:(NSArray *)arguments options:(ATLaunchUnixTaskAndCaptureOutputOptions)options completionHandler:(ATLaunchUnixTaskAndCaptureOutputCompletionHandler)completionHandler {
    return ATLaunchUnixTaskAndCaptureOutput(self.scriptFileURL, arguments, options, completionHandler);
}

- (BOOL)updateProperties:(NSDictionary *)newProperties {
    if ([_properties isEqualToDictionary:newProperties])
        return NO;
    else {
        [_properties release];
        _properties = [newProperties copy];
        return YES;
    }
}

@end
