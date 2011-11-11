
#import "CompilationSettingsWindowController.h"

#import "PluginManager.h"
#import "Compiler.h"
#import "RubyVersion.h"
#import "ToolOptions.h"

#import "UIBuilder.h"


#define kWindowTopMargin 118
#define kWindowBottomMargin 100



@interface CompilationSettingsWindowController () {
    NSArray               *_compilerOptions;
    BOOL                   _populatingRubyVersions;
    NSArray               *_rubyVersions;
}

- (void)populateToolVersions;

@end



@implementation CompilationSettingsWindowController

@synthesize nodeVersionsPopUpButton = _nodeVersionsPopUpButton;
@synthesize rubyVersionsPopUpButton = _rubyVersionsPopUpButton;

- (void)dealloc {
    [_compilerOptions release], _compilerOptions = nil;
    [_rubyVersions release], _rubyVersions = nil;
    [super dealloc];
}


#pragma mark - Actions

- (IBAction)showHelp:(id)sender {
    TenderShowArticle(@"features/compilation");
}


#pragma mark - Compiler settings

- (void)renderOptions:(NSArray *)options forCompiler:(Compiler *)compiler withBuilder:(UIBuilder *)builder isFirst:(BOOL *)isFirstCompiler {
    if (!*isFirstCompiler)
        [builder addVisualBreak];
    *isFirstCompiler = NO;

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

- (void)renderCompilerOptions {
    NSArray *compilers = _project.compilersInUse;
    NSMutableArray *allOptions = [[NSMutableArray alloc] init];

    UIBuilder *builder = [[UIBuilder alloc] initWithWindow:self.window];
    [builder buildUIWithTopInset:kWindowTopMargin bottomInset:kWindowBottomMargin block:^{
        if (compilers.count > 0) {
            BOOL isFirst = YES;
            for (Compiler *compiler in compilers) {
                NSArray *options = [compiler optionsForProject:_project];
                [self renderOptions:options forCompiler:compiler withBuilder:builder isFirst:&isFirst];
                [allOptions addObjectsFromArray:options];
            }
        } else {
            [builder addFullWidthLabel:@"No compilable files found in this folder."];
        }
    }];
    [builder release];

    _compilerOptions = [[NSArray alloc] initWithArray:allOptions];
    [allOptions release];
}

- (void)render {
    [self renderCompilerOptions];
    [self populateToolVersions];
}

- (void)save {
    for (ToolOption *option in _compilerOptions) {
        [option save];
    }
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

            // might involve invocation of Rubies, so do this before removeAllItems to avoid flicker
            NSArray *titles = [_rubyVersions valueForKeyPath:@"displayTitle"];

            [_rubyVersionsPopUpButton removeAllItems];
            [_rubyVersionsPopUpButton addItemsWithTitles:titles];
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
