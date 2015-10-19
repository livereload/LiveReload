@import Foundation;

NS_ASSUME_NONNULL_BEGIN


extern NSString *const UserScriptManagerScriptsDidChangeNotification;

extern NSString *const UserScriptErrorDomain;
enum {
    UserScriptErrorMissingScript,
    UserScriptErrorInvalidScript,
};


@protocol UserScriptResult;


@interface UserScript : NSObject

@property(nonatomic, readonly) NSString *friendlyName;
@property(nonatomic, readonly) NSString *uniqueName;
@property(nonatomic, readonly) NSString *path;
@property(nonatomic, readonly) BOOL exists;

- (void)invokeForProjectAtPath:(NSString *)projectPath withModifiedFiles:(NSSet *)paths result:(id<UserScriptResult>)result completionHandler:(dispatch_block_t)completionHandler;

@end


@protocol UserScriptResult

- (void)addRawOutput:(NSString *_Nonnull)rawOutput withCompletionBlock:(dispatch_block_t _Nonnull)completionBlock;

- (void)completedWithInvocationError:(NSError *_Nullable)error;

@end


@interface MissingUserScript : UserScript

- (id)initWithName:(NSString *)name;

@end



@interface UserScriptManager : NSObject

+ (UserScriptManager *)sharedUserScriptManager;

@property(nonatomic, readonly) NSArray *userScripts;

- (void)revealUserScriptsFolderSelectingScript:(UserScript *)selectedScript;

@end

NS_ASSUME_NONNULL_END
