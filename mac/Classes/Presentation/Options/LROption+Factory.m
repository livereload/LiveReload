
#import "LROption+Factory.h"

#import "LRCheckboxOption.h"
#import "LRTextFieldOption.h"
#import "LRPopUpOption.h"


@implementation LROption (Factory)

+ (NSDictionary *)standardOptionTypes {
    static NSDictionary *result;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        result = @{
            @"checkbox": LRCheckboxOption.class,
            @"text-field": LRTextFieldOption.class,
            @"popup": LRPopUpOption.class,
        };
    });
    return result;
}

+ (LROption *)optionWithSpec:(NSDictionary *)spec action:(Action *)action errorSink:(id<LRManifestErrorSink>)errorSink {
    NSString *typeName = spec[@"type"];
    if (!typeName.length)
        return nil;
    Class klass = [[self standardOptionTypes] objectForKey:typeName];
    if (!klass)
        return nil;;
    return [[klass alloc] initWithManifest:spec action:action errorSink:errorSink];
}

@end
