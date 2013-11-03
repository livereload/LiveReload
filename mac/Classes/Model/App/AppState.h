//
//  AppState.h
//  LiveReload
//
//  Created by Andrey Tarantsov on 10/17/13.
//
//

#import <Foundation/Foundation.h>

@interface AppState : NSObject

+ (AppState *)sharedAppState;
+ (void)initializeAppState;

@property(nonatomic) NSInteger numberOfConnectedBrowsers;
@property(nonatomic) NSInteger numberOfRefreshesProcessed;
@property(nonatomic) NSInteger numberOfChangedFiles;

@end
