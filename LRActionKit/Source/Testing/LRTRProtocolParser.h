@import Foundation;
#import "LRTRGlobals.h"


@protocol LRTRProtocolParserDelegate;


@interface LRTRProtocolParser : NSObject

@property(nonatomic, weak) id<LRTRProtocolParserDelegate> delegate;

- (void)processLine:(NSString *)line;

- (void)finish;

@end


@protocol LRTRProtocolParserDelegate <NSObject>

- (void)finishedTestNamed:(NSString *)name withStatus:(LRTRTestStatus)status;

- (void)appendExtraOutput:(NSString *)output;

@end
