
#import <Foundation/Foundation.h>

#define ShitHappened(message, ...) _ShitHappened([NSString stringWithFormat:@"Error in %@:%d [%@ %s]", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, NSStringFromClass([self class]), _cmd], message, ## __VA_ARGS__)
#define CShitHappened(message, ...) _ShitHappened([NSString stringWithFormat:@"Error in %@:%d", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__], message, ## __VA_ARGS__)

void TenderStartDiscussion(NSString *subject, NSString *body);
void TenderStartDiscussionIn(NSString *category);

void TenderShowArticle(NSString *url);

void TenderDisplayHelp();

void _ShitHappened(NSString *subject, NSString *message, ...) NS_FORMAT_FUNCTION(2,3);
