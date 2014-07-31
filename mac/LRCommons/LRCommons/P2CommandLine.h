
#import <Foundation/Foundation.h>


NSArray *P2ParseCommandLineSpec(id spec);


@interface P2QuotingStyle : NSObject

@property(nonatomic, copy) NSString *startString;
@property(nonatomic, copy) NSString *endString;
@property(nonatomic) unichar escapeCharacter;
@property(nonatomic, copy) NSDictionary *escapeSequences;

+ (id)quotingStyleWithStartString:(NSString *)startString endString:(NSString *)endString escapeCharacter:(unichar)escapeCharacter escapeSequences:(NSDictionary *)escapeSequences;

- (BOOL)scanQuotedStringWithScanner:(NSScanner *)scanner intoString:(NSString **)string;

- (BOOL)isPerfectQuotingStyleForString:(NSString *)string;

- (NSString *)quoteString:(NSString *)string;

@end


@interface NSString (P2CommandLine)

- (NSArray *)p2_argumentsArrayUsingBourneQuotingStyle;

@end


@interface NSArray (P2CommandLine)

- (NSString *)p2_quotedArgumentStringUsingBourneQuotingStyle;

@end
