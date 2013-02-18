#import "NSWindow+Additions.h"


@implementation NSWindow (Extensions)

-(NSPoint)midpoint
{
  NSRect frame = [self frame];
  NSPoint midpoint = NSMakePoint(frame.origin.x + (frame.size.width/2),
                               frame.origin.y + (frame.size.height/2));
  return midpoint;
}
-(void)setMidpoint:(NSPoint)midpoint
{
  NSRect frame = [self frame];
  frame.origin = NSMakePoint(midpoint.x - (frame.size.width/2),
                             midpoint.y - (frame.size.height/2));
  [self setFrame:frame display:YES];
}


@end
