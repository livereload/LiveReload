
#import "Editor.h"

@implementation Editor

- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}

+ (Editor *)detectEditor {
    return nil;
}

+ (NSString *)editorDisplayName {
    return NSStringFromClass(self);
}

- (NSString *)name {
    return [[self class] editorDisplayName];
}

- (BOOL)jumpToFile:(NSString *)file line:(NSInteger)line {
    return NO;
}

@end
