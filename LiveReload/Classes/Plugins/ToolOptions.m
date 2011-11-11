
#import "ToolOptions.h"

#import "Compiler.h"
#import "Project.h"
#import "UIBuilder.h"



@interface ToolOption() {
@protected
    Compiler              *_compiler;
    Project               *_project;
    NSDictionary          *_info;

    NSString              *_identifier;
}

- (id)initWithCompiler:(Compiler *)compiler project:(Project *)project optionInfo:(NSDictionary *)optionInfo;

- (void)parse;

@end



@interface CheckBoxToolOption : ToolOption
@end



@interface SelectToolOption : ToolOption
@end



@interface EditToolOption : ToolOption
@end



Class ToolOptionClassByType(NSString *type) {
    if ([type isEqualToString:@"checkbox"]) {
        return [CheckBoxToolOption class];
    } else if ([type isEqualToString:@"select"]) {
        return [SelectToolOption class];
    } else if ([type isEqualToString:@"edit"]) {
        return [EditToolOption class];
    } else {
        return nil;
    }
}



@implementation ToolOption

@synthesize identifier=_identifier;


#pragma mark - Init/dealloc

+ (ToolOption *)toolOptionWithCompiler:(Compiler *)compiler project:(Project *)project optionInfo:(NSDictionary *)optionInfo {
    NSString *type = [optionInfo objectForKey:@"Type"];
    Class klass = ToolOptionClassByType(type);
    if (klass) {
        return [[[klass alloc] initWithCompiler:compiler project:project optionInfo:optionInfo] autorelease];
    } else {
        return nil;
    }
}

- (id)initWithCompiler:(Compiler *)compiler project:(Project *)project optionInfo:(NSDictionary *)optionInfo {
    self = [super init];
    if (self) {
        _compiler = [compiler retain];
        _project = [project retain];
        _info = [optionInfo copy];

        _identifier = [optionInfo objectForKey:@"Id"];

        [self parse];
    }
    return self;
}

- (void)dealloc {
    [_compiler release], _compiler = nil;
    [_project release], _project = nil;
    [_info release], _info = nil;
    [_identifier release], _identifier = nil;
    [super dealloc];
}


#pragma mark - Rendering

- (void)renderControlWithBuilder:(UIBuilder *)builder {
}

- (void)renderWithBuilder:(UIBuilder *)builder {
    [self renderControlWithBuilder:builder];
    NSString *label = [_info objectForKey:@"Label"];
    if (label.length > 0) {
        [builder addLabel:label];
    }
}


#pragma mark - Stubs

- (void)parse {
}

- (void)save {
}

@end



@implementation CheckBoxToolOption {
    NSString              *_title;

    NSButton              *_view;
}

- (void)parse {
    _title = [[_info objectForKey:@"Title"] copy];
}

- (void)dealloc {
    [_title release], _title = nil;
    [_view release], _view = nil;
    [super dealloc];
}

- (void)renderControlWithBuilder:(UIBuilder *)builder {
    _view = [[builder addCheckboxWithTitle:_title] retain];
}

- (void)save {
}

@end



@implementation SelectToolOption {
    NSArray               *_items;

    NSPopUpButton         *_view;
}

- (void)parse {
    _items = [[_info objectForKey:@"Items"] copy];
}

- (void)dealloc {
    [_items release], _items = nil;
    [_view release], _view = nil;
    [super dealloc];
}

- (void)renderControlWithBuilder:(UIBuilder *)builder {
    _view = [[builder addPopUpButton] retain];
    [_view addItemsWithTitles:[_items valueForKeyPath:@"Title"]];
}

- (void)save {
}


@end



@implementation EditToolOption {
    NSString              *_placeholder;

    NSTextField           *_view;
}

- (void)parse {
    _placeholder = [[_info objectForKey:@"Placeholder"] copy];
}

- (void)dealloc {
    [_placeholder release], _placeholder = nil;
    [_view release], _view = nil;
    [super dealloc];
}

- (void)renderControlWithBuilder:(UIBuilder *)builder {
    _view = [[builder addTextField] retain];
    if (_placeholder.length > 0) {
        [_view.cell setPlaceholderString:_placeholder];
    }
}

- (void)save {
}

@end
