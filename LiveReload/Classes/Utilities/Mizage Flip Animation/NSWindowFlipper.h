/*
 This code was originally written by Tyler from Mizage (http://mizage.com)
 This code is licensed under the "Feel free to use this however you want. A shout out would be cool." license.
 Enjoy!
*/

#import <Cocoa/Cocoa.h>

//This little class is used to accomodate performSelector:withObject:afterDelay.
@interface FlipArguments : NSObject
{
  NSWindow* toWindow; //the window to which we are flipping
  CFTimeInterval duration; //the duration of the flip
  BOOL shadowed; //draw a shadow under the window while flipping
}
-(id)initWithToWindow:(NSWindow*)ToWindow flipDuration:(CFTimeInterval)Duration shadowed:(BOOL)Shadowed;
@property(readonly,nonatomic)NSWindow* toWindow;
@property(readonly,nonatomic)CFTimeInterval duration;
@property(readonly,nonatomic)BOOL shadowed;
@end

@interface NSWindow (Flipper)

-(void)flipToWindow:(NSWindow*)to withDuration:(CFTimeInterval)duration shadowed:(BOOL)shadowed;
-(void)flipWithArguments:(FlipArguments*)flipArguments;

@end
