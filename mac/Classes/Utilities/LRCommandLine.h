
#import <Foundation/Foundation.h>


NSArray *LRParseCommandLineSpec(id spec);


@interface ATQuotingStyle : NSObject

@property(nonatomic, copy) NSString *startString;
@property(nonatomic, copy) NSString *endString;
@property(nonatomic) unichar escapeCharacter;
@property(nonatomic, copy) NSDictionary *escapeSequences;

+ (id)quotingStyleWithStartString:(NSString *)startString endString:(NSString *)endString escapeCharacter:(unichar)escapeCharacter escapeSequences:(NSDictionary *)escapeSequences;

- (BOOL)scanQuotedStringWithScanner:(NSScanner *)scanner intoString:(NSString **)string;

- (BOOL)isPerfectQuotingStyleForString:(NSString *)string;

- (NSString *)quoteString:(NSString *)string;

@end


@interface NSString (LRCommandLine)

- (NSArray *)argumentsArrayUsingBourneQuotingStyle;

@end


@interface NSArray (LRCommandLine)

- (NSString *)quotedArgumentStringUsingBourneQuotingStyle;

@end
