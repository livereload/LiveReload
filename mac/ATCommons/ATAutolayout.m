
#import "ATAutolayout.h"
#import <objc/runtime.h>



@interface ATAutolayoutAutomaticBindingsDictionary : NSDictionary

- (id)initWithOwner:(id)owner;
+ (id)dictionaryWithOwner:(id)owner;

@end


@implementation ATAutolayoutAutomaticBindingsDictionary {
    id _owner;
}

- (id)initWithOwner:(id)owner {
    self = [super init];
    if (self) {
        _owner = owner;
    }
    return self;
}

+ (id)dictionaryWithOwner:(id)owner  {
    return [[[self class] alloc] initWithOwner:owner];
}

- (NSUInteger)count {
    abort();
//    return 0;
}

- (NSEnumerator *)keyEnumerator {
    abort();
//    return [[NSArray array] objectEnumerator];
}

- (id)objectForKey:(id)aKey {
    return [_owner valueForKey:aKey];
}


@end


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

//            NSLog(@"Replacing %@ with %@", constraint, newConstraint);
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

const void *ATMetricsKey = "ATMetricsKey";
- (NSDictionary *)AT_metrics {
    return objc_getAssociatedObject(self, ATMetricsKey);
}

- (void)setAT_metrics:(NSDictionary *)metrics {
    objc_setAssociatedObject(self, ATMetricsKey, metrics, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSArray *)addConstraintsWithVisualFormat:(NSString *)format {
    return [self addConstraintsWithVisualFormat:format options:0];
}

- (NSArray *)addConstraintsWithVisualFormat:(NSString *)format options:(NSLayoutFormatOptions)opts {
    return [self addAndReturnConstraints:[self constraintsWithVisualFormat:format options:opts]];
}

- (NSArray *)addAndReturnConstraints:(NSArray *)constraints {
    [self addConstraints:constraints];
    return constraints;
}

- (NSArray *)constraintsWithVisualFormat:(NSString *)format options:(NSLayoutFormatOptions)opts {
    return [NSLayoutConstraint constraintsWithVisualFormat:format options:opts metrics:self.AT_metrics views:[ATAutolayoutAutomaticBindingsDictionary dictionaryWithOwner:self]];
}

- (NSArray *)addFullHeightConstraintsForSubview:(NSView *)subview {
    return [self addAndReturnConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[subview]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(subview)]];
}

@end
