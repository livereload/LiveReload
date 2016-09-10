@import Foundation;


@class ATPathSpec;


@interface FilterOption : NSObject

+ (instancetype)filterOptionWithSubfolder:(NSString *)folderRelPath;
@property(nonatomic, readonly, copy) NSString *subfolder;

+ (instancetype)filterOptionWithMemento:(NSString *)memento;
@property(nonatomic, readonly, copy) NSString *memento;

@property(nonatomic, readonly, strong) NSString *displayName;
@property(nonatomic, readonly, strong) ATPathSpec *pathSpec;

@property(nonatomic, readonly, copy) NSString *folderRelPath;
@property(nonatomic, readonly) NSUInteger folderComponentCount;

- (BOOL)isEqualToFilterOption:(FilterOption *)peer;

@property(nonatomic) BOOL valid;

@end
