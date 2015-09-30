@import Foundation;


@class RuntimeRepository;
@class RuntimeInstance;

extern NSString *const RuntimeReferenceResolvedInstanceDidChangeNotification;


@interface RuntimeReference : NSObject

- (instancetype)initWithRepository:(RuntimeRepository *)repository;

@property (nonatomic) NSString *identifier;
@property (nonatomic) RuntimeInstance *instance;

@property (nonatomic, copy) dispatch_block_t identifierDidChangeBlock;

@end
