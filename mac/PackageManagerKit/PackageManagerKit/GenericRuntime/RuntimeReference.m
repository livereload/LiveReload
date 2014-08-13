#import "RuntimeReference.h"
#import "RuntimeRepository.h"
#import "RuntimeInstance.h"


NSString *const RuntimeReferenceResolvedInstanceDidChangeNotification = @"RuntimeReferenceResolvedInstanceDidChange";


@interface RuntimeReference ()

@property (nonatomic, readonly) RuntimeRepository *repository;

@end


@implementation RuntimeReference

- (instancetype)initWithRepository:(RuntimeRepository *)repository {
    self = [super init];
    if (self) {
        _repository = repository;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_updateInstance) name:LRRuntimesDidChangeNotification object:repository];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setIdentifier:(NSString *)identifier {
    if (![_identifier isEqualToString:identifier]) {
        _identifier = [identifier copy];

        [self _updateInstance];

        if (_identifierDidChangeBlock) {
            _identifierDidChangeBlock();
        }
    }
}

- (void)setInstance:(RuntimeInstance *)instance {
    self.identifier = instance.identifier;
}

- (void)_updateInstance {
    _instance = ((_identifier.length > 0) ? [_repository instanceIdentifiedBy:_identifier] : nil);
    [[NSNotificationCenter defaultCenter] postNotificationName:RuntimeReferenceResolvedInstanceDidChangeNotification object:self];
}

@end
