@import LRCommons;

#import "OptionsRow.h"


@implementation OptionsRow {
    NSBox *_box;
    LROptionsView *_optionsView;
}

- (NSBox *)box {
    [self loadContentIfNeeded];
    return _box;
}

- (LROptionsView *)optionsView {
    [self loadContentIfNeeded];
    return _optionsView;
}

- (void)loadContent {
    [super loadContent];

    _box = [[NSBox box] addedToView:self];
    _optionsView = [[LROptionsView optionsView] addedToView:_box];
    [_box addConstraintsWithVisualFormat:@"H:|-8-[optionsView]-8-|" options:0 referencingPropertiesOfObject:self];
    [_box addConstraintsWithVisualFormat:@"V:|-8-[optionsView]-12-|" options:0 referencingPropertiesOfObject:self];

    [self addConstraintsWithVisualFormat:@"|-indentL3-[box]|"];
    [self addConstraintsWithVisualFormat:@"V:|[box]|"];

    self.topMargin = 8;
    self.bottomMargin = 16;

    if (_loadContentBlock)
        _loadContentBlock();
}

@end
