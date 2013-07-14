
#import "LRPluginCommons.h"
#import "RegexKitLite.h"


NSDictionary *LRExtractMetadata(NSString *content) {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];

    [content enumerateStringsMatchedByRegex:@"^(?:#|//|--)\\s*LR-([a-zA-Z0-9-]+):(.*)$" options:RKLMultiline inRange:NSMakeRange(0, NSUIntegerMax) error:nil enumerationOptions:0 usingBlock:^(NSInteger captureCount, NSString *const *capturedStrings, const NSRange *capturedRanges, volatile BOOL *const stop) {
        //        NSLog(@"Match: %@  :::  %@  :::  %@", capturedStrings[0], capturedStrings[1], capturedStrings[2]);
        NSString *key = [capturedStrings[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *value = [capturedStrings[2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        properties[key] = value;
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
            if (!props[@"plugin-api"]) {
                NSLog(@"LRFindPluginsInFolder: Not a plugin (missing LR-plugin-api key): %@", item);
                continue;
            }
            if (![validApiValues containsObject:props[@"plugin-api"]]) {
                NSLog(@"LRFindPluginsInFolder: Unsupported LR-plugin-api value '%@' in '%@', looking for LR-plugin-api values: %@", props[@"plugin-api"], item, [validApiValues componentsJoinedByString:@", or "]);
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

- (id)invokeWithArguments:(NSArray *)arguments options:(LaunchUnixTaskAndCaptureOutputOptions)options completionHandler:(LaunchUnixTaskAndCaptureOutputCompletionHandler)completionHandler {
    return LaunchUnixTaskAndCaptureOutput(self.scriptFileURL, arguments, options, completionHandler);
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
