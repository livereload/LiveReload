
#import "EKJumpRequest.h"

@implementation EKJumpRequest

@synthesize fileURL = _fileURL;
@synthesize line = _line;
@synthesize column = _column;

- (id)initWithFileURL:(NSURL*)fileURL line:(int)line column:(int)column {
    self = [super init];
    if (self) {
        _fileURL = fileURL;
        _line = line;
        _column = column;
    }
    return self;
}

- (NSString *)componentsJoinedByString:(NSString *)separator {
    NSMutableArray *array = [NSMutableArray arrayWithObject:self.fileURL.path];
    if (self.line != EKJumpRequestValueUnknown) {
        [array addObject:[NSString stringWithFormat:@"%d", self.line]];

        if (self.column != EKJumpRequestValueUnknown) {
            [array addObject:[NSString stringWithFormat:@"%d", self.column]];
        }
    }
    return [array componentsJoinedByString:separator];
}

- (NSString *)description {
    return [self componentsJoinedByString:@":"];
}

- (int)computeLinearOffsetWithError:(NSError **)outError {
    NSError *error;
    NSString *content = [NSString stringWithContentsOfURL:self.fileURL usedEncoding:NULL error:&error];
    if (!content) {
        if (outError)
            *outError = error;
        return EKJumpRequestValueUnknown;
    }

    int line = self.line;
    int column = self.column;
    __block int curline = 0;
    __block int offset = -1;
    __block int lastOffset = -1;
    [content enumerateSubstringsInRange:NSMakeRange(0, content.length) options:NSStringEnumerationByLines|NSStringEnumerationSubstringNotRequired usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        ++curline;
        if (curline == line) {
            offset = (int)substringRange.location;
            if (column != EKJumpRequestValueUnknown) {
                offset += MIN((int)substringRange.length, (column - 1));
            }
            *stop = YES;
        }
        lastOffset = (int)substringRange.location;
    }];

    if (offset == -1) {
        if (lastOffset >= 0)
            offset = lastOffset;  // if the specified line does not exist (the number is too large), jump to the start of the last line
        else
            offset = 0;  // oops, no lines in the file at all
    }

    return offset;
}

@end
