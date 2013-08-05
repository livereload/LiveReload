
#import "ImportGraph.h"

@implementation ImportGraph

- (id)init {
    self = [super init];
    if (self) {
        _filesToNodes = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)removeAllPaths {
    [_filesToNodes removeAllObjects];
}

- (ImportGraphNode *)nodeForPath:(NSString *)path {
    ImportGraphNode *node = [_filesToNodes objectForKey:path];
    if (node == nil) {
        node = [[ImportGraphNode alloc] initWithPath:path];
        [_filesToNodes setObject:node forKey:path];
    }
    return node;
}

- (void)removeReferencingPath:(NSString *)referencingPath fromReferencedPath:(NSString *)referencedPath {
    ImportGraphNode *referencedNode = [_filesToNodes objectForKey:referencedPath];
    if (referencedNode) {
        [referencedNode->_referencingPaths removeObject:referencingPath];
        if (![referencedNode isNotEmpty])
            [_filesToNodes removeObjectForKey:referencedNode];
    }
}

- (void)removeReferencedPath:(NSString *)referencedPath fromReferencingPath:(NSString *)referencingPath {
    ImportGraphNode *referencingNode = [_filesToNodes objectForKey:referencingPath];
    if (referencingNode) {
        [referencingNode->_referencedPaths removeObject:referencedPath];
        if (![referencingNode isNotEmpty])
            [_filesToNodes removeObjectForKey:referencingPath];
    }
}

- (void)setRereferencedPaths:(NSSet *)referencedPaths forPath:(NSString *)path {
    ImportGraphNode *node = [self nodeForPath:path];
    for (NSString *referencedPath in node->_referencedPaths) {
        if (![referencedPaths containsObject:referencedPath]) {
            [self removeReferencingPath:path fromReferencedPath:referencedPath];
        }
    }
    for (NSString *referencedPath in referencedPaths) {
        if (![node->_referencedPaths containsObject:referencedPath]) {
            [[self nodeForPath:referencedPath]->_referencingPaths addObject:path];
        }
    }
    [node->_referencedPaths removeAllObjects];
    [node->_referencedPaths unionSet:referencedPaths];
}

- (void)removePath:(NSString *)path collectingPathsToRecomputeInto:(NSMutableSet *)pathsToRecompute {
    ImportGraphNode *node = [_filesToNodes objectForKey:path];
    if (node) {
        for (NSString *referencingPath in node->_referencingPaths) {
            [self removeReferencedPath:path fromReferencingPath:referencingPath];
            [pathsToRecompute addObject:referencingPath];
        }
        for (NSString *referencedPath in node->_referencedPaths) {
            [self removeReferencingPath:path fromReferencedPath:referencedPath];
        }
    }
    [_filesToNodes removeObjectForKey:path];
}

// returns YES if the given path has any referencing paths, NO if the given path is a root path
- (BOOL)addRootReferencingPathsForPath:(NSString *)path into:(NSMutableSet *)result visited:(NSMutableSet *)visited {
    [visited addObject:path];
    ImportGraphNode *node = [_filesToNodes objectForKey:path];
    if (node && [node->_referencingPaths count] > 0) {
        for (NSString *referencingPath in node->_referencingPaths) {
            if ([visited containsObject:referencingPath])
                continue;
            if (![self addRootReferencingPathsForPath:referencingPath into:result visited:visited]) {
                [result addObject:referencingPath];
            }
        }
        return YES;
    } else {
        return NO;
    }
}

- (NSSet *)rootReferencingPathsForPath:(NSString *)path {
    NSMutableSet *result = [NSMutableSet set];
    [self addRootReferencingPathsForPath:path into:result visited:[NSMutableSet set]];
    return result;
}

- (BOOL)hasReferencingPathsForPath:(NSString *)path {
    ImportGraphNode *node = [_filesToNodes objectForKey:path];
    return node && [node->_referencingPaths count] > 0;
}


- (NSString *)description {
    NSMutableString *result = [NSMutableString string];
    [result appendString:@"Forward graph:\n"];
    [_filesToNodes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        ImportGraphNode *node = obj;
        for (NSString *referencedPath in node->_referencedPaths) {
            [result appendFormat:@"  %@ -> %@\n", key, referencedPath];
        }
    }];
    [result appendString:@"Reverse graph:\n"];
    [_filesToNodes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        ImportGraphNode *node = obj;
        for (NSString *referencingPath in node->_referencingPaths) {
            [result appendFormat:@"  %@ <- %@\n", key, referencingPath];
        }
    }];
    return result;
}

@end


@implementation ImportGraphNode

- (id)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        _path = [path copy];
        _referencedPaths = [[NSMutableSet alloc] init];
        _referencingPaths = [[NSMutableSet alloc] init];
    }
    return self;
}

- (BOOL)isNotEmpty {
    return [_referencedPaths count] > 0 || [_referencingPaths count] > 0;
}


@end
