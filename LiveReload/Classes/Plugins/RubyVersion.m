
#import "RubyVersion.h"

#import "NSTask+OneLineTasksWithOutput.h"
#import "NSData+Base64.h"
#import "ATSandboxing.h"
#include "nodeapp.h"


NSString *RubyVersionsDidChangeNotification = @"RubyVersionsDidChangeNotification";



static NSString *RubyVersionAtPath(NSString *path) {
    NSError *error = nil;
    NSArray *components = [[[NSTask stringByLaunchingPath:path withArguments:[NSArray arrayWithObject:@"--version"] error:&error] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (error)
        return nil;
    if ([[components objectAtIndex:0] isEqualToString:@"ruby"] && components.count > 1)
        return [components objectAtIndex:1];
    return nil;
}



@interface RvmInstance ()

+ (void)saveRvmInstances;

- (id)initWithPath:(NSString *)path bookmark:(NSData *)bookmark savedPath:(NSString *)savedPath;

@property(nonatomic, readonly) NSString *path;
@property(nonatomic, readonly) NSData *bookmark;

@end



@interface RubyVersion ()

- (void)validate;

@end



@interface SystemRubyVersion : RubyVersion {
    NSString              *_versionName;
    BOOL                   _valid;
}
@end



@interface RvmRubyVersion : RubyVersion {
    NSString              *_name;
    NSString              *_rootPath;
    BOOL                   _valid;
}

- (id)initWithName:(NSString *)name rootPath:(NSString *)rootPath;

@end



@implementation RubyVersion

- (void)validate {
}
- (NSString *)identifier {
    return nil;
}
- (NSString *)title {
    return nil;
}
- (NSString *)executablePath {
    return nil;
}
- (NSDictionary *)environmentModifications {
    return [NSDictionary dictionary];
}
- (BOOL)isValid {
    return YES;
}

- (NSString *)displayTitle {
    if ([self isValid])
        return [self title];
    else
        return [NSString stringWithFormat:@"%@ (missing)", [self title]];
}

+ (RubyVersion *)rubyVersionWithIdentifier:(NSString *)identifier {
    if ([identifier isEqualToString:@"system"]) {
        return [[[SystemRubyVersion alloc] init] autorelease];
    } else if ([identifier rangeOfString:@"rvm:"].location == 0) {
        for (RvmInstance *instance in [RvmInstance rvmInstances]) {
            for (RubyVersion *version in [instance availableRubyVersions]) {
                if ([version.identifier isEqualToString:identifier]) {
                    return version;
                }
            }
        }
        return nil;
    } else {
        return nil;
    }
}

+ (NSArray *)availableRubyVersions {
    NSMutableArray *result = [NSMutableArray array];
    [result addObject:[[[SystemRubyVersion alloc] init] autorelease]];
    
    for (RvmInstance *instance in [RvmInstance rvmInstances]) {
        [result addObjectsFromArray:[instance availableRubyVersions]];
    }

    return [NSArray arrayWithArray:result];
}

@end



@implementation SystemRubyVersion

- (id)init {
    self = [super init];
    if (self) {
        [self validate];
    }
    return self;
}

- (void)dealloc {
    [_versionName release], _versionName = nil;
    [super dealloc];
}

- (NSString *)identifier {
    return @"system";
}

- (NSString *)executablePath {
    return @"/usr/bin/ruby";
}

- (void)validate {
    NSFileManager *fm = [NSFileManager defaultManager];
    _valid = [fm fileExistsAtPath:[self executablePath]];
}

- (BOOL)isValid {
    return _valid;
}

- (NSString *)title {
    if (_versionName == nil) {
        _versionName = [RubyVersionAtPath(self.executablePath) retain];
    }
    if (self.valid && _versionName)
        return [NSString stringWithFormat:@"System Ruby %@", _versionName];
    else
        return @"System Ruby";
}

@end



@implementation RvmRubyVersion

- (id)initWithName:(NSString *)name rootPath:(NSString *)rootPath {
    self = [super init];
    if (self) {
        _name = [name copy];
        _rootPath = [rootPath copy];
        [self validate];
    }
    return self;
}

- (void)dealloc {
    [_name release], _name = nil;
    [super dealloc];
}

- (NSString *)identifier {
    return [NSString stringWithFormat:@"rvm:%@", _name];
}

- (NSString *)rubyHomePath {
    return [_rootPath stringByAppendingPathComponent:[NSString stringWithFormat:@"rubies/%@", _name]];
}

- (NSString *)executablePath {
    return [_rootPath stringByAppendingPathComponent:[NSString stringWithFormat:@"bin/%@", _name]];
}

- (void)validate {
    NSFileManager *fm = [NSFileManager defaultManager];
    _valid = [fm fileExistsAtPath:[self rubyHomePath]] && [fm fileExistsAtPath:[[self executablePath] stringByResolvingSymlinksInPath]];
}

- (BOOL)isValid {
    return _valid;
}

- (NSString *)title {
    return [NSString stringWithFormat:@"%@ (rvm)", _name];
}

@end



static dispatch_queue_t rvm_instances_queue;
static NSMutableArray *rvmInstances;

@implementation RvmInstance {
    NSString *_path;
    NSData *_bookmark;
}

@synthesize path=_path;
@synthesize bookmark=_bookmark;

+ (void)initialize {
    rvm_instances_queue = dispatch_queue_create("com.livereload.rvm_instances", NULL);
}

+ (NSString *)rvmDataPath {
    return [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"LiveReload/Data/rvms.json"];
}

+ (void)loadRvmInstances {
    if (!rvmInstances) {
        rvmInstances = [[NSMutableArray alloc] init];
        
        NSString *path = [self rvmDataPath];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingUncached error:NULL];
            
            json_error_t error;
            json_t *json = json_loadb(data.bytes, data.length, 0, &error);
            for (int len = json_array_size(json), i = 0; i < len; ++i) {
                json_t *instance_json = json_array_get(json, i);
                BOOL sandboxed = json_bool_value(json_object_get(instance_json, "sandboxed"));
                if (ATIsSandboxed() && !sandboxed) {
                    // bookmark came from non-sandboxed LiveReload; ignore because it's useless
                    continue;
                }
                NSString *path = NSStr(json_string_value(json_object_get(instance_json, "path")));
                NSString *bookmarkBase64 = NSStr(json_string_value(json_object_get(instance_json, "bookmark")));
                NSData *bookmark = [NSData dataFromBase64String:bookmarkBase64];
                
                [rvmInstances addObject:[[[RvmInstance alloc] initWithPath:nil bookmark:bookmark savedPath:path] autorelease]];
            }
            json_decref(json);
        }
        
        if (!ATIsSandboxed() && rvmInstances.count == 0) {
            NSString *typicalPath = [@"~/.rvm" stringByExpandingTildeInPath];
            if ([[NSFileManager defaultManager] fileExistsAtPath:typicalPath]) {
                [rvmInstances addObject:[[[RvmInstance alloc] initWithPath:typicalPath bookmark:nil savedPath:nil] autorelease]];
                [self saveRvmInstances];
            }
        }
    }
}

+ (NSArray *)rvmInstances {
    dispatch_sync(rvm_instances_queue, ^{
        [self loadRvmInstances];
    });
    return rvmInstances;
}

+ (void)saveRvmInstances {
    dispatch_async(rvm_instances_queue, ^{
        [self loadRvmInstances];
        NSString *path = [self rvmDataPath];
        [[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
        
        json_t *json = json_array();
        for (RvmInstance *instance in rvmInstances) {
            json_array_append_new(json, json_object_3("path", json_nsstring(instance.path), "bookmark", json_nsstring([instance.bookmark base64EncodedString]), "sandboxed", json_bool(ATIsSandboxed())));
        }

        char *string = json_dumps(json, JSON_INDENT(2));
        [[NSData dataWithBytesNoCopy:string length:strlen(string) freeWhenDone:NO] writeToFile:path options:NSDataWritingAtomic error:NULL];
        free(string);

        json_decref(json);
    });
}

+ (void)addRvmInstanceAtPath:(NSString *)path {
    dispatch_async(rvm_instances_queue, ^{
        [self loadRvmInstances];
        [rvmInstances addObject:[[[RvmInstance alloc] initWithPath:path bookmark:nil savedPath:nil] autorelease]];
        [[NSNotificationCenter defaultCenter] postNotificationName:RubyVersionsDidChangeNotification object:nil];

        [self saveRvmInstances];
    });
}

- (id)initWithPath:(NSString *)path bookmark:(NSData *)bookmark savedPath:(NSString *)savedPath {
    self = [super init];
    if (self) {
        if (!path) {
            NSError *error = nil;
            BOOL stale = NO;
            NSURL *url = [NSURL URLByResolvingBookmarkData:bookmark options:ATIfSandboxed(NSURLBookmarkResolutionWithSecurityScope, 0) relativeToURL:nil bookmarkDataIsStale:&stale error:&error];
            [url startAccessingSecurityScopedResource];
            path = [url path];
            if (!path) {
                NSLog(@"Cannot resolve RVM bookmark at %@: %@", savedPath, [error description]);
            }
            if (path && stale) {
                bookmark = NULL; // regenerate
            }
        }
        if (!bookmark) {
            NSError *error = nil;
            bookmark = [[NSURL fileURLWithPath:path] bookmarkDataWithOptions:ATIfSandboxed(NSURLBookmarkCreationWithSecurityScope|NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess, 0) includingResourceValuesForKeys:[NSArray array] relativeToURL:nil error:&error];
        }
        _bookmark = [bookmark copy];
        _path = [path copy];
    }
    return self;
}

- (NSArray *)availableRubyVersions {
    NSMutableArray *result = [NSMutableArray array];

    NSString *rvmRubiesFolder = [_path stringByAppendingPathComponent:@"rubies"];
    for (NSString *name in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:rvmRubiesFolder error:nil]) {
        NSString *path = [rvmRubiesFolder stringByAppendingPathComponent:name];
        BOOL isDir = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir) {
            RubyVersion *version = [[[RvmRubyVersion alloc] initWithName:name rootPath:_path] autorelease];
            if (version.valid) {
                [result addObject:version];
            } else {
                NSLog(@"Found invalid RVM ruby: %@", name);
            }
        }
    }
    
    return result;
}


@end
