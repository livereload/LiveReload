
#import "ATAutolayout.h"


@implementation NSView (ATAutolayout)

- (void)replaceSubviewPreservingConstraints:(NSView *)oldView with:(NSView *)newView {
    NSView *superview = self;

    newView.translatesAutoresizingMaskIntoConstraints = NO;

    NSMutableArray *oldConstraints = [NSMutableArray new];
    NSMutableArray *newConstraints = [NSMutableArray new];
    for (NSLayoutConstraint *constraint in superview.constraints) {
        if (constraint.firstItem == oldView || constraint.secondItem == oldView) {
            [oldConstraints addObject:constraint];

            id firstItem = (constraint.firstItem == oldView ? newView : constraint.firstItem);
            id secondItem = (constraint.secondItem == oldView ? newView : constraint.secondItem);

            NSLayoutConstraint *newConstraint = [NSLayoutConstraint constraintWithItem:firstItem attribute:constraint.firstAttribute relatedBy:constraint.relation toItem:secondItem attribute:constraint.secondAttribute multiplier:constraint.multiplier constant:constraint.constant];
            [newConstraints addObject:newConstraint];

            NSLog(@"Replacing %@ with %@", constraint, newConstraint);
        }
    }

    [superview removeConstraints:oldConstraints];
    [newView removeFromSuperview];
    [superview replaceSubview:oldView with:newView];
    [superview addConstraints:newConstraints];

//    NSLog(@"Old constraints: %@", oldConstraints);
//    NSLog(@"New constraints: %@", newConstraints);
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
//        NSTableView *tableView = (id)newView;
//        NSView *columnView = [tableView viewAtColumn:0 row:0 makeIfNecessary:YES];
//        //        [superview.window visualizeConstraints:[columnView constraintsAffectingLayoutForOrientation:NSLayoutConstraintOrientationHorizontal]];
//        [superview.window visualizeConstraints:newConstraints];
//
//        NSLog(@"Intrinsic size = %@", NSStringFromSize(tableView.intrinsicContentSize));
//    });
}

- (void)replaceWithViewPreservingConstraints:(NSView *)newView {
    [self.superview replaceSubviewPreservingConstraints:self with:newView];
}

@end
