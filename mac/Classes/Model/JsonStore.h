
#import <Foundation/Foundation.h>

@interface JsonStore : NSObject

@end


@protocol JsonConvertible <NSObject>

- (NSDictionary *)memento;

- (void)setMemento:(NSDictionary *)data;

@end