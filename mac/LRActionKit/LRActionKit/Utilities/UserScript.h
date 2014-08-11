@import Foundation;


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

- (void)addRawOutput:(NSString *)rawOutput withCompletionBlock:(dispatch_block_t)completionBlock;

- (void)completedWithInvocationError:(NSError *)error;

@end


@interface MissingUserScript : UserScript

- (id)initWithName:(NSString *)name;

@end



@interface UserScriptManager : NSObject

+ (UserScriptManager *)sharedUserScriptManager;

@property(nonatomic, readonly) NSArray *userScripts;

- (void)revealUserScriptsFolderSelectingScript:(UserScript *)selectedScript;

@end
