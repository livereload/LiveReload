
#import "CompilationSettingsWindowController.h"

#import "PluginManager.h"
#import "Compiler.h"
#import "RubyVersion.h"
#import "ToolOptions.h"

#import "UIBuilder.h"


#define kWindowTopMargin 118
#define kWindowBottomMargin 100



@interface CompilationSettingsWindowController () {

    BOOL                   _populatingRubyVersions;
    NSArray               *_rubyVersions;
}

- (void)populateToolVersions;

@end



@implementation CompilationSettingsWindowController

@synthesize nodeVersionsPopUpButton = _nodeVersionsPopUpButton;
@synthesize rubyVersionsPopUpButton = _rubyVersionsPopUpButton;


#pragma mark - Actions

- (IBAction)showHelp:(id)sender {
    TenderShowArticle(@"features/compilation");
}


#pragma mark - Compiler settings

- (void)renderSettingsForCompiler:(Compiler *)compiler withBuilder:(UIBuilder *)builder isFirst:(BOOL *)isFirstCompiler {
    if (!*isFirstCompiler)
        [builder addVisualBreak];
    *isFirstCompiler = NO;

    NSArray *options = [compiler optionsForProject:_project];

    BOOL isFirst = YES;
    for (ToolOption *option in options) {
        [option renderWithBuilder:builder];

        if (isFirst && !builder.labelAdded) {
            [builder addLabel:[NSString stringWithFormat:@"%@:", compiler.name]];
        }
        isFirst = NO;
    }

    if (isFirst) {
        [builder addRightLabel:@"No options for this compiler"];
        [builder addLabel:[NSString stringWithFormat:@"%@:", compiler.name]];
    }
}


#pragma mark - Model sync

- (void)render {
    NSArray *compilers = _project.compilersInUse;

    UIBuilder *builder = [[UIBuilder alloc] initWithWindow:self.window];
    [builder buildUIWithTopInset:kWindowTopMargin bottomInset:kWindowBottomMargin block:^{
        if (compilers.count > 0) {
            BOOL isFirst = YES;
            for (Compiler *compiler in compilers) {
                [self renderSettingsForCompiler:compiler withBuilder:builder isFirst:&isFirst];
            }
        } else {
            [builder addFullWidthLabel:@"No compilable files found in this folder."];
        }
    }];
    [builder release];

    [self populateToolVersions];
}

- (void)save {
}


#pragma mark - Tool Versions

- (void)populateRubyVersions {
    if (_populatingRubyVersions)
        return;
    _populatingRubyVersions = YES;

    if (_rubyVersionsPopUpButton.tag != 0x101) {
        _rubyVersionsPopUpButton.tag = 0x101;
        [_rubyVersionsPopUpButton removeAllItems];
        [_rubyVersionsPopUpButton addItemWithTitle:@"Loading…"];
        [_rubyVersionsPopUpButton setEnabled:NO];
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSArray *version = [[RubyVersion availableRubyVersions] retain];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_rubyVersions release], _rubyVersions = version;

            [_rubyVersionsPopUpButton removeAllItems];

            // find the selected item
            NSInteger selectedIndex = -1, index = 0;
            for (RubyVersion *version in _rubyVersions) {
                if ([_project.rubyVersionIdentifier isEqualToString:version.identifier])
                    selectedIndex = index;
                ++index;
            }

            // add if not found
            if (selectedIndex < 0) {
                RubyVersion *version = [RubyVersion rubyVersionWithIdentifier:_project.rubyVersionIdentifier];
                [_rubyVersions autorelease];
                _rubyVersions = [[[NSArray arrayWithObject:version] arrayByAddingObjectsFromArray:_rubyVersions] retain];
                selectedIndex = 0;
            }

            for (RubyVersion *version in _rubyVersions) {
                [_rubyVersionsPopUpButton addItemWithTitle:version.displayTitle];
            }
            [_rubyVersionsPopUpButton setEnabled:YES];
            [_rubyVersionsPopUpButton selectItemAtIndex:selectedIndex];

            _populatingRubyVersions = NO;
        });
    });
}

- (void)populateToolVersions {
    [self populateRubyVersions];
}

- (IBAction)nodeVersionsPopUpValueDidChange:(id)sender {
}

- (IBAction)rubyVersionsPopUpValueDidChange:(id)sender {
    NSInteger index = [_rubyVersionsPopUpButton indexOfSelectedItem];
    if (index < 0)
        return;
    RubyVersion *version = [_rubyVersions objectAtIndex:index];
    _project.rubyVersionIdentifier = version.identifier;
}


@end
