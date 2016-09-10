#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


NSArray<NSString *> *P2ParseCommandLineSpec(id _Nullable spec);


@interface P2QuotingStyle : NSObject

@property(nonatomic, copy) NSString *startString;
@property(nonatomic, copy) NSString *endString;
@property(nonatomic) unichar escapeCharacter;
@property(nonatomic, copy) NSDictionary *escapeSequences;

+ (instancetype)quotingStyleWithStartString:(NSString *)startString endString:(NSString *)endString escapeCharacter:(unichar)escapeCharacter escapeSequences:(NSDictionary *)escapeSequences;

- (BOOL)scanQuotedStringWithScanner:(NSScanner *)scanner intoString:(NSString *_Nullable *_Nullable)string;

- (BOOL)isPerfectQuotingStyleForString:(NSString *)string;

- (NSString *)quoteString:(NSString *)string;

@end


@interface NSString (P2CommandLine)

- (NSArray<NSString *> *)p2_argumentsArrayUsingBourneQuotingStyle;

@end


@interface NSArray (P2CommandLine)

- (NSString *)p2_quotedArgumentStringUsingBourneQuotingStyle;

@end

NS_ASSUME_NONNULL_END