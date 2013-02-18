/*
 This code was originally written by Tyler from Mizage (http://mizage.com)
 This code is licensed under the "Feel free to use this however you want. A shout out would be cool." license.
 Enjoy!
*/


#import "NSWindowFlipper.h"
#import <QuartzCore/QuartzCore.h>

#import "NSWindow+Additions.h"

@implementation FlipArguments

@synthesize toWindow,duration,shadowed;

-(id)initWithToWindow:(NSWindow*)ToWindow flipDuration:(CFTimeInterval)Duration shadowed:(BOOL)Shadowed;
{
  if(self = [super init])
  {
    toWindow = ToWindow;
    duration = Duration;
    shadowed = Shadowed;
  }
  return self;
}

@end

@interface NSWindowFlipperDelegate : NSObject
{
  NSWindow* fromWindow;
  NSWindow* toWindow;
  NSWindow* fromFlipWindow;
  NSWindow* toFlipWindow;
}
-(id)initWithFromWindow:(NSWindow*)FromWindow toWindow:(NSWindow*)ToWindow fromFlipWindow:(NSWindow*)FromFlipWindow toFlipWindow:(NSWindow*)ToFlipWindow;
@end

@interface NSWindowFlipperDelegate (Private)
-(id)autoreleasePrivate;
@end

//This class is used to do the final few steps after the animation has completed
@implementation NSWindowFlipperDelegate

-(id)initWithFromWindow:(NSWindow*)FromWindow toWindow:(NSWindow*)ToWindow fromFlipWindow:(NSWindow*)FromFlipWindow toFlipWindow:(NSWindow*)ToFlipWindow
{
  if(self = [super init])
  {
    fromWindow = FromWindow;
    toWindow = ToWindow;
    fromFlipWindow = FromFlipWindow;
    toFlipWindow = ToFlipWindow;
  }
  return self;
}

//Called when the flip finishes. Tears down the window images we made and brings the window we flipped to into focus
-(void)animationDidStop:(CAAnimation*)animation finished:(BOOL)flag
{
  NSDisableScreenUpdates();
  [fromFlipWindow close];
  [toFlipWindow close];

  [toWindow setAlphaValue:1.0];
  [toWindow makeKeyWindow];

  NSEnableScreenUpdates();
  [self autoreleasePrivate];
}

-(id)autoreleasePrivate
{
  return [super autorelease];
}
-(id)autorelease
{
  //no-op to shut up the static analyzer
  return self;
}
@end

@implementation NSWindow (Flipper)

-(void)flipToWindow:(NSWindow*)to withDuration:(CFTimeInterval)duration shadowed:(BOOL)shadowed
{
  FlipArguments* args = [[FlipArguments alloc] initWithToWindow:to flipDuration:duration shadowed:shadowed];
  [self flipWithArguments:args];
  [args release];
}

-(void)flipWithArguments:(FlipArguments*)flipArguments
{
  NSWindow* toWindow = [flipArguments toWindow];
  CFTimeInterval duration = [flipArguments duration];
  BOOL shadowed = [flipArguments shadowed];

  //Center the toWindow under the fromWindow
  [toWindow setMidpoint:[self midpoint]];

  //force redisplay of hidden window so we get an up to date image
  [toWindow display];

  NSString* animationKey = @"transform";
  //Create two windows to contain images of the windows
  NSWindow* flipFromWindow = [[NSWindow alloc] initWithContentRect:NSInsetRect([self frame],-100,-100)
                                                         styleMask:NSBorderlessWindowMask
                                                           backing:NSBackingStoreBuffered
                                                             defer:NO];
  [flipFromWindow setOpaque:NO];
  [flipFromWindow setHasShadow:NO];
  [flipFromWindow setBackgroundColor:[NSColor clearColor]];

  NSWindow* flipToWindow = [[NSWindow alloc] initWithContentRect:NSInsetRect([toWindow frame],-100,-100)
                                                       styleMask:NSBorderlessWindowMask
                                                         backing:NSBackingStoreBuffered
                                                           defer:NO];
  [flipToWindow setOpaque:NO];
  [flipToWindow setHasShadow:NO];
  [flipToWindow setBackgroundColor:[NSColor clearColor]];

  //Two temp views to get some data
  NSView* tempFrom = [[self contentView] superview];
  NSView* tempTo = [[toWindow contentView] superview];

  NSRect tempFromBounds = [tempFrom bounds];
  NSRect tempToBounds = [tempTo bounds];

  //Grab the bitmap of the windows
  NSBitmapImageRep* fromBitmap = [tempFrom bitmapImageRepForCachingDisplayInRect:tempFromBounds];
  [tempFrom cacheDisplayInRect:tempFromBounds toBitmapImageRep:fromBitmap];

  NSBitmapImageRep* toBitmap = [tempTo bitmapImageRepForCachingDisplayInRect:tempToBounds];
  [tempTo cacheDisplayInRect:tempToBounds toBitmapImageRep:toBitmap];


  //Create two views sized to their respective windows
  NSView* fromView = [[[NSView alloc] initWithFrame:tempFromBounds] autorelease];
  NSView* toView = [[[NSView alloc] initWithFrame:tempToBounds] autorelease];

  [fromView setWantsLayer:YES];
  [fromView setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
  [toView setWantsLayer:YES];
  [toView setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];

  //Add the views to the windows
  [flipFromWindow setContentView:fromView];
  [flipToWindow setContentView:toView];

  //Create two layers sized to their respective windows
  CGRect fromLayerBounds = NSRectToCGRect(tempFromBounds);
  CGRect toLayerBounds = NSRectToCGRect(tempToBounds);

  CALayer* fromLayer = [CALayer layer];
  [fromLayer setFrame:fromLayerBounds];

  CALayer* toLayer = [CALayer layer];
  [toLayer setFrame:toLayerBounds];

  //Fill the layers with the bitmaps
  [fromLayer setContents:(id)[fromBitmap CGImage]];
  [toLayer setContents:(id)[toBitmap CGImage]];

  //Turn off double sided so layer will cull when not facing us
  [fromLayer setDoubleSided:NO];
  [toLayer setDoubleSided:NO];

  //Set up gravity
  [fromLayer setContentsGravity:kCAGravityCenter];
  [toLayer setContentsGravity:kCAGravityCenter];

  //Make the layer we are flipping have a rotation of M_PI so it is facing away and culled
  [toLayer setValue:[NSValue valueWithCATransform3D:CATransform3DMakeRotation(M_PI, 0.0f, 1.0f, 0.0f)] forKeyPath:animationKey];

  if(shadowed)
  {
    //Create shadows on the layers - the shadow varies between versions of OSX.
    //I should really write some code to accomodate it, but it hasn't been critical as we don't use it.
    //Keep in mind, the shadow drawn is a filled box. If your view is transparent, it will look weird.
    //Basically this shadow is really poorly implemented and needs to be done properly.
    int shadowRadius = 14;
    CGSize offset = CGSizeMake(0,-22.5);
    float opacity = 0.4;

    [fromLayer setShadowColor:CGColorGetConstantColor(kCGColorBlack)];
    [fromLayer setShadowRadius:shadowRadius];
    [fromLayer setShadowOffset:offset];
    [fromLayer setShadowOpacity:opacity];
    [toLayer setShadowColor:CGColorGetConstantColor(kCGColorBlack)];
    [toLayer setShadowRadius:shadowRadius];
    [toLayer setShadowOffset:offset];
    [toLayer setShadowOpacity:opacity];
  }

  //Add the layers to their respective views
  [fromView setLayer:fromLayer];
  [toView setLayer:toLayer];

  //We need to disable screen updates so all this setup doesn't cause weird visual flickering, etc
  NSDisableScreenUpdates();

  //Bring up the new bitmapped windows
  [flipToWindow orderFront:nil];
  [flipFromWindow orderFront:nil];
  [flipToWindow display];
  [flipFromWindow display];

  //Remove the original window
  [self orderOut:nil];

  //Bring up the destination window
  [toWindow setAlphaValue:0.0];
  [toWindow orderFront:nil];

  //Our flippers are in place and ready to go, enable updates to draw them. They should look identical at this point
  NSEnableScreenUpdates();

  //Set up the animation
  CABasicAnimation* fromAnimation = [CABasicAnimation animationWithKeyPath:animationKey];
  CABasicAnimation* toAnimation = [CABasicAnimation animationWithKeyPath:animationKey];

  [fromAnimation setRemovedOnCompletion:NO];
  [toAnimation setRemovedOnCompletion:NO];

  //The zDistance is what makes it look like the window is rotating around a center. Playing with this value is fun. Try it!
  int zDistance = 850;

  CATransform3D fromTransform = CATransform3DIdentity;
  fromTransform.m34 = 1.0 / -zDistance;
  fromTransform = CATransform3DRotate(fromTransform,M_PI,0.0f, 1.0f, 0.0f);

  CATransform3D toTransform = CATransform3DIdentity;
  toTransform.m34 = 1.0 / -zDistance;
  toTransform = CATransform3DRotate(toTransform,2*M_PI,0.0f, 1.0f, 0.0f);

  //Apply all our options to our animations
  [fromAnimation setFromValue:[NSValue valueWithCATransform3D:CATransform3DIdentity]];
  [fromAnimation setToValue:[NSValue valueWithCATransform3D:fromTransform]];
  [fromAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
  [toAnimation setFromValue:[NSValue valueWithCATransform3D:CATransform3DMakeRotation(M_PI, 0.0f, 1.0f, 0.0f)]];
  [toAnimation setToValue:[NSValue valueWithCATransform3D:toTransform]];
  [toAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];

  CGEventRef event = CGEventCreate(NULL);
  CGEventFlags modifiers = CGEventGetFlags(event);
  CFRelease(event);

  //For fun. Hold shift to double duration of flip. Hold shift and control to quadruple it.
  if(modifiers & kCGEventFlagMaskShift)
    duration *= 2;
  if((modifiers & kCGEventFlagMaskShift) && (modifiers & kCGEventFlagMaskControl))
    duration *= 4;

  [fromAnimation setDuration:duration];
  [toAnimation setDuration:duration];

  //Create our delegate to do final teardown and such. We only apply it to one animation.
  NSWindowFlipperDelegate* delegate = [[NSWindowFlipperDelegate alloc] initWithFromWindow:self
                                                                                 toWindow:toWindow
                                                                           fromFlipWindow:flipFromWindow
                                                                             toFlipWindow:flipToWindow];
  [toAnimation setDelegate:[delegate autorelease]];


  //Fire animations
  [fromLayer setValue:[NSValue valueWithCATransform3D:fromTransform] forKeyPath:animationKey];
  [fromLayer addAnimation:fromAnimation forKey:animationKey];
  [toLayer setValue:[NSValue valueWithCATransform3D:toTransform] forKeyPath:animationKey];
  [toLayer addAnimation:toAnimation forKey:animationKey];
}

@end
