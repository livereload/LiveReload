//
//  AppState.h
//  LiveReload
//
//  Created by Andrey Tarantsov on 10/17/13.
//
//

#import <Foundation/Foundation.h>


@class LRPackageManager;


@interface AppState : NSObject

+ (AppState *)sharedAppState;
+ (void)initializeAppState;

@property(nonatomic, readonly) LRPackageManager *packageManager;

@property(nonatomic) NSInteger numberOfConnectedBrowsers;
@property(nonatomic) NSInteger numberOfRefreshesProcessed;
@property(nonatomic) NSInteger numberOfChangedFiles;

@end
