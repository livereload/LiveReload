
#import "ProjectCell.h"

@implementation ProjectCell

@synthesize delegate;
@synthesize titleLabel;
@synthesize compileCoffeeScriptCheckbox;

#pragma mark -
#pragma mark Init/dealloc

- (id)initWithReusableIdentifier:(NSString*)identifier {
    NSLog(@"- [ProjectCell initWithReusableIdentifier] at %p", self);
    return [super initWithReusableIdentifier:identifier];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    NSLog(@"- [ProjectCell initWithCoder] at %p", self);
    return [super initWithCoder:aDecoder];
}

- (id)init {
    NSLog(@"- [ProjectCell init] at %p", self);
    self = [super init];
    NSLog(@"- [ProjectCell init] after super call, self = %p", self);
    return self;
}

- (void)awakeFromNib {
    NSLog(@"- [ProjectCell awakeFromNib] at %p", self);
}

- (void)dealloc {
    [titleLabel release], titleLabel=nil;

    [super dealloc];
}

#pragma mark -
#pragma mark Reuse

- (void)prepareForReuse {
    [titleLabel setStringValue:@""];
}

#pragma mark -
#pragma mark Drawing

- (void)drawRect:(NSRect)dirtyRect {
    if([self isSelected]) {
        [[NSColor selectedControlColor] set];
    } else {
        NSArray *colors = [NSColor controlAlternatingRowBackgroundColors];
        [[colors objectAtIndex:self.row % [colors count]] set];
    }
    NSRectFill(self.bounds);
}


#pragma mark -
#pragma mark Accessibility

- (NSArray*)accessibilityAttributeNames {
    NSMutableArray*    attribs = [[[super accessibilityAttributeNames] mutableCopy] autorelease];

    [attribs addObject: NSAccessibilityRoleAttribute];
    [attribs addObject: NSAccessibilityDescriptionAttribute];
    [attribs addObject: NSAccessibilityTitleAttribute];
    [attribs addObject: NSAccessibilityEnabledAttribute];

    return attribs;
}

- (BOOL)accessibilityIsAttributeSettable:(NSString *)attribute {
    if( [attribute isEqualToString: NSAccessibilityRoleAttribute]
       || [attribute isEqualToString: NSAccessibilityDescriptionAttribute]
       || [attribute isEqualToString: NSAccessibilityTitleAttribute]
       || [attribute isEqualToString: NSAccessibilityEnabledAttribute] )
    {
        return NO;
    }
    else
        return [super accessibilityIsAttributeSettable: attribute];
}

- (id)accessibilityAttributeValue:(NSString*)attribute {
    if ([attribute isEqualToString:NSAccessibilityRoleAttribute]) {
        return NSAccessibilityButtonRole;
    }
    if([attribute isEqualToString:NSAccessibilityDescriptionAttribute]
           || [attribute isEqualToString:NSAccessibilityTitleAttribute]) {
        return [titleLabel stringValue];
    }
    if([attribute isEqualToString:NSAccessibilityEnabledAttribute]) {
        return [NSNumber numberWithBool:YES];
    }

    return [super accessibilityAttributeValue:attribute];
}

- (IBAction)compileCoffeeScriptChanged:(id)sender {
    [delegate checkboxClickedForLanguage:@"coffee" inCell:self];
}

@end
