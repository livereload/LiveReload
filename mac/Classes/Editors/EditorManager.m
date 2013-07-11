
#import "EditorManager.h"
#import "ATSandboxing.h"
#import "RegexKitLite.h"

#import "CustomEditor.h"
#import "CodaEditor.h"
#import "EspressoEditor.h"
#import "SublimeText2Editor.h"
#import "SubEthaEditEditor.h"
#import "TextMateEditor.h"
#import "BBEditEditor.h"
#import "ExternalEditor.h"


static NSDictionary *EMExtractExternalScriptMetadata(NSURL *file) {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];

    NSError *error;
    NSString *content = [NSString stringWithContentsOfURL:file encoding:NSUTF8StringEncoding error:&error];
    if (!content) {
        NSLog(@"Failed to read file at %@", file);
        return properties;
    }

    [content enumerateStringsMatchedByRegex:@"^(?:#|//|--)\\s*LR-([a-zA-Z0-9-]+):(.*)$" options:RKLMultiline inRange:NSMakeRange(0, NSUIntegerMax) error:nil enumerationOptions:0 usingBlock:^(NSInteger captureCount, NSString *const *capturedStrings, const NSRange *capturedRanges, volatile BOOL *const stop) {
//        NSLog(@"Match: %@  :::  %@  :::  %@", capturedStrings[0], capturedStrings[1], capturedStrings[2]);
        NSString *key = [capturedStrings[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *value = [capturedStrings[2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        properties[key] = value;
    }];

    return properties;
}

static NSArray *EMFindPluginsInFolder(NSURL *folder) {
    NSFileManager *fm = [NSFileManager defaultManager];

    NSMutableArray *plugins = [NSMutableArray array];
    NSError *error;
    NSArray *contents = [fm contentsOfDirectoryAtURL:folder includingPropertiesForKeys:@[NSFileType] options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
    NSLog(@"EMFindPluginsInFolder(%@): %@", folder, contents);
    for (NSURL *item in contents) {
        NSDictionary *attrs = [item resourceValuesForKeys:@[NSURLIsRegularFileKey, NSURLIsSymbolicLinkKey, NSURLIsReadableKey, NSURLIsExecutableKey] error:nil];
        if ([attrs[NSURLIsRegularFileKey] boolValue] || [attrs[NSURLIsSymbolicLinkKey ] boolValue]) {
            NSDictionary *props = EMExtractExternalScriptMetadata(item);
            if (![props[@"plugin-api"] isEqualToString:@"editor v1"]) {
                NSLog(@"Skipping unsupported plugin at %@ (missing or invalid LR-plugin-api key)", item);
                continue;
            }
            NSLog(@"Props of %@: %@", item, props);

            [plugins addObject:@{@"scriptURL": item, @"props": props}];
        }
    }

    return plugins;
}


@interface EditorManager ()

@property(nonatomic, readonly, strong) NSMutableArray *editors;

@end


@implementation EditorManager

@synthesize editors = _editors;

+ (EditorManager *)sharedEditorManager {
    static dispatch_once_t onceQueue;
    static EditorManager *editorManager = nil;

    dispatch_once(&onceQueue, ^{ editorManager = [[self alloc] init]; });
    return editorManager;
}

- (id)init {
    self = [super init];
    if (self) {
        _editors = [[NSMutableArray alloc] init];
        [self detectEditors];
    }
    return self;
}

- (Editor *)activeEditor {
//    for (Class editorClass in _editorClasses) {
//        Editor *editor = [editorClass detectEditor];
//        if (editor)
//            return editor;
//    }
    return nil;
}

- (void)detectEditors {
    [_editors removeAllObjects];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSArray *plugins = EMFindPluginsInFolder([ATUserScriptsDirectoryURL() URLByAppendingPathComponent:@"Editors"]);
        dispatch_async(dispatch_get_main_queue(), ^{
            for (NSDictionary *item in plugins) {
                Editor *editor = [[ExternalEditor alloc] initWithScriptFileURL:item[@"scriptURL"] properties:item[@"props"]];
                [_editors addObject:editor];
                [editor updateStateSoon];
            }
        });
    });
}

@end
