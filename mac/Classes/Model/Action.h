
#import <Foundation/Foundation.h>
#import "UserScript.h"
#import "ATPathSpec.h"
#import "FilterOption.h"


@interface Action : NSObject

+ (NSString *)typeIdentifier;
@property(nonatomic, readonly) NSString *typeIdentifier;

- (id)initWithMemento:(NSDictionary *)memento;
@property(nonatomic, copy) NSDictionary *memento;

// automatically invoked when reading
- (void)loadFromMemento:(NSDictionary *)memento;
- (void)updateMemento:(NSMutableDictionary *)memento;

@property(nonatomic) BOOL enabled;

@property(nonatomic, readonly, getter = isNonEmpty) BOOL nonEmpty;

@property(nonatomic, strong) FilterOption *inputFilterOption;
@property(nonatomic, strong) ATPathSpec *inputPathSpec;

- (void)invokeForProjectAtPath:(NSString *)projectPath withModifiedFiles:(NSSet *)paths completionHandler:(UserScriptCompletionHandler)completionHandler;

//- (void)invokeForFileAtPath:(NSString *)sourceRelPath into:(NSString *)destinationRelPath under:(NSString *)rootPath inProject:(Project *)project completionHandler:(UserScriptCompletionHandler)completionHandler;

@end
