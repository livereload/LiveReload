//
//  AppState.h
//  LiveReload
//
//  Created by Andrey Tarantsov on 10/17/13.
//
//

#import <Foundation/Foundation.h>


@class LRPackageManager;
@class RuntimeReference;
@class RubyRuntimeRepository;


@interface AppState : NSObject

+ (AppState *)sharedAppState;
+ (void)initializeAppState;

- (void)finishLaunching;

@property(nonatomic, readonly) LRPackageManager *packageManager;
@property(nonatomic, readonly) RubyRuntimeRepository *rubyRuntimeRepository;
@property(nonatomic, readonly) RuntimeReference *defaultRubyRuntimeReference;

@property(nonatomic) NSInteger numberOfConnectedBrowsers;
@property(nonatomic) NSInteger numberOfRefreshesProcessed;
@property(nonatomic) NSInteger numberOfChangedFiles;

@end
