#import "FilterOption.h"
@import ATPathSpec;


@implementation FilterOption

- (instancetype)initWithSubfolder:(NSString *)subfolder {
    self = [super init];
    if (self) {
        subfolder = ATPathSpecRemoveTrailingSlash(subfolder);
        if ([subfolder isEqualToString:@"."])
            subfolder = @"";
        _subfolder = [subfolder copy];
        _pathSpec = [ATPathSpec pathSpecMatchingPath:subfolder type:ATPathSpecEntryTypeFolder syntaxOptions:ATPathSpecSyntaxFlavorLiteral];
        _valid = YES;
    }
    return self;
}

+ (instancetype)filterOptionWithSubfolder:(NSString *)subfolder {
    return [[[self class] alloc] initWithSubfolder:subfolder];
}

+ (instancetype)filterOptionWithMemento:(NSString *)memento {
    if ([memento hasPrefix:@"subdir:"])
        return [self filterOptionWithSubfolder:[memento substringFromIndex:[@"subdir:" length]]];
    return nil;
}

- (NSString *)folderRelPath {
    return _subfolder;
}

- (NSUInteger)folderComponentCount {
    if (_subfolder.length == 0)
        return 0;
    else
        return _subfolder.pathComponents.count;
}

- (NSString *)memento {
    NSString *path = (_subfolder.length == 0 ? @"." : _subfolder);
    return [@"subdir:" stringByAppendingString:path];
}

- (NSString *)displayName {
    if (_subfolder.length == 0)
        return @"./";
    else
        return ATPathSpecAddTrailingSlash(_subfolder);
}

- (id)copy {
    return self;
}

- (NSUInteger)hash {
    return [_subfolder hash];
}

- (BOOL)isEqualToFilterOption:(FilterOption *)peer {
    return [peer->_subfolder isEqualToString:_subfolder];
}

- (BOOL)isEqual:(id)object {
    return [object isKindOfClass:[self class]] && [self isEqualToFilterOption:object];
}

@end
