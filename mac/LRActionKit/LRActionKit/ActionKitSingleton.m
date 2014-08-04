#import "ActionKitSingleton.h"
#import "LRActionKit-Swift.h"


@implementation ActionKitSingleton

static ActionKitSingleton *sharedActionKit;

+ (instancetype)sharedActionKit {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedActionKit = [ActionKitSingleton new];
    });
    return sharedActionKit;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _optionRegistry = [OptionRegistry new];
        [_optionRegistry addOptionType:[CheckboxOptionType new]];
        [_optionRegistry addOptionType:[MultipleChoiceOptionType new]];
        [_optionRegistry addOptionType:[TextOptionType new]];
    }
    return self;
}

@end
