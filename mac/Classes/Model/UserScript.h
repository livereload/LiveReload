
#import <Foundation/Foundation.h>


extern NSString *const UserScriptManagerScriptsDidChangeNotification;

extern NSString *const UserScriptErrorDomain;
enum {
    UserScriptErrorMissingScript,
    UserScriptErrorInvalidScript,
};


@class ToolOutput;


@interface UserScript : NSObject

@property(nonatomic, readonly) NSString *friendlyName;
@property(nonatomic, readonly) NSString *uniqueName;
@property(nonatomic, readonly) NSString *path;
@property(nonatomic, readonly) BOOL exists;

typedef void (^UserScriptCompletionHandler)(BOOL invoked, ToolOutput *output, NSError *error);

- (void)invokeForProjectAtPath:(NSString *)projectPath withModifiedFiles:(NSSet *)paths completionHandler:(UserScriptCompletionHandler)completionHandler;

@end


@interface MissingUserScript : UserScript

- (id)initWithName:(NSString *)name;

@end



@interface UserScriptManager : NSObject

+ (UserScriptManager *)sharedUserScriptManager;

@property(nonatomic, readonly) NSArray *userScripts;

- (void)revealUserScriptsFolderSelectingScript:(UserScript *)selectedScript;

@end
