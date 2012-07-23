
#import <Foundation/Foundation.h>


extern NSString *const UserScriptManagerScriptsDidChangeNotification;

extern NSString *const UserScriptErrorDomain;
enum {
    UserScriptErrorMissingScript,
};


@class ToolOutput;


@interface UserScript : NSObject

@property(nonatomic, readonly) NSString *friendlyName;
@property(nonatomic, readonly) NSString *uniqueName;
@property(nonatomic, readonly) NSString *path;
@property(nonatomic, readonly) BOOL exists;

- (BOOL)invokeForProjectAtPath:(NSString *)path withModifiedFiles:(NSSet *)paths output:(ToolOutput **)output error:(NSError **)error;

@end


@interface MissingUserScript : UserScript

- (id)initWithName:(NSString *)name;

@end



@interface UserScriptManager : NSObject

+ (UserScriptManager *)sharedUserScriptManager;

@property(nonatomic, readonly) NSArray *userScripts;

- (void)revealUserScriptsFolderSelectingScript:(UserScript *)selectedScript;

@end
