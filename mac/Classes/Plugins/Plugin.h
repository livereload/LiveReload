
#import <Foundation/Foundation.h>


@interface Plugin : NSObject {
@private
    NSString         *_path;
    NSDictionary     *_info;
    NSArray          *_compilers;
}

- (id)initWithPath:(NSString *)path;

@property(nonatomic, readonly) NSString *path;
@property(nonatomic, readonly) NSArray *compilers;
@property(nonatomic, readonly) NSArray *actionTypes;

@property(nonatomic, readonly) NSArray *errors;
- (void)addErrorMessage:(NSString *)message;

@end
