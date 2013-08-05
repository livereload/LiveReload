
#import "ToolOptions.h"

#import "Compiler.h"
#import "Project.h"
#import "CompilationOptions.h"
#import "UIBuilder.h"

#import "NSArray+ATSubstitutions.h"



@interface ToolOption() {
@protected
    Compiler              *_compiler;
    Project               *_project;
    NSDictionary          *_info;

    NSString              *_identifier;
}

- (id)initWithCompiler:(Compiler *)compiler project:(Project *)project optionInfo:(NSDictionary *)optionInfo;

- (void)parse;

@property(nonatomic, strong) id storedValue;
@property(unsafe_unretained, nonatomic, readonly) id currentValue;

- (id)defaultValue; // subclasses must override
- (id)newValue;     // subclasses must override
- (void)updateNewValue;

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
        return [[klass alloc] initWithCompiler:compiler project:project optionInfo:optionInfo];
    } else {
        return nil;
    }
}

- (id)initWithCompiler:(Compiler *)compiler project:(Project *)project optionInfo:(NSDictionary *)optionInfo {
    self = [super init];
    if (self) {
        _compiler = compiler;
        _project = project;
        _info = [optionInfo copy];

        _identifier = [[optionInfo objectForKey:@"Id"] copy];

        [self parse];
    }
    return self;
}


#pragma mark - Values

- (id)storedValue {
    CompilationOptions *options = [_project optionsForCompiler:_compiler create:NO];
    return [options valueForOptionIdentifier:_identifier];
}

- (void)setStoredValue:(id)value {
    CompilationOptions *options = [_project optionsForCompiler:_compiler create:YES];
    [options setValue:value forOptionIdentifier:_identifier];
}

- (id)currentValue {
    return self.storedValue ?: self.defaultValue;
}

- (id)defaultValue {
    NSAssert(NO, @"Must implement defaultValue");
    return nil;
}

- (id)newValue {
    NSAssert(NO, @"Must implement newValue");
    return nil;
}

- (void)updateNewValue {
    [self setStoredValue:[self newValue]];
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
    [self updateNewValue];
}

- (NSArray *)currentCompilerArguments {
    return [NSArray array];
}

@end



#pragma mark - Check Box

@implementation CheckBoxToolOption {
    NSString              *_title;

    NSButton              *_view;
}

- (void)parse {
    _title = [[_info objectForKey:@"Title"] copy];
}

- (id)defaultValue {
    return [NSNumber numberWithBool:NO];
}

- (id)newValue {
    return [NSNumber numberWithBool:_view.state == NSOnState];
}

- (void)renderControlWithBuilder:(UIBuilder *)builder {
    _view = [builder addCheckboxWithTitle:_title];
    [_view setTarget:self];
    [_view setAction:@selector(checkBoxClicked:)];
    _view.state = [self.currentValue boolValue] ? NSOnState : NSOffState;
}

- (IBAction)checkBoxClicked:(id)sender {
    [self updateNewValue];
}

- (NSArray *)currentCompilerArguments {
    id arg = nil;
    if ([self.currentValue boolValue]) {
        arg = [_info objectForKey:@"OnArgument"];
    } else {
        arg = [_info objectForKey:@"OffArgument"];
    }
    if ([arg isKindOfClass:[NSArray class]])
        return arg;
    else if ([arg isKindOfClass:[NSString class]])
        return [arg componentsSeparatedByString:@" "];
    else
        return [NSArray array];
}

@end



#pragma mark - Enabled

@implementation EnabledToolOption {
    NSButton              *_view;
}

- (void)renderControlWithBuilder:(UIBuilder *)builder {
    CompilationOptions *options = [_project optionsForCompiler:_compiler create:YES];
    _view = [builder addCheckboxWithTitle:@"Enabled"];
    [_view setTarget:self];
    [_view setAction:@selector(checkBoxClicked:)];
    _view.state = options.enabled ? NSOnState : NSOffState;
}

- (IBAction)checkBoxClicked:(id)sender {
    [self save];
}

- (void)save {
    CompilationOptions *options = [_project optionsForCompiler:_compiler create:YES];
    options.enabled = (_view.state == NSOnState);
}

@end



#pragma mark - Select

@implementation SelectToolOption {
    NSArray               *_items;

    NSPopUpButton         *_view;
}

- (void)parse {
    _items = [[_info objectForKey:@"Items"] copy];
}

- (id)defaultValue {
    return [[_items objectAtIndex:0] objectForKey:@"Id"];
}

- (id)newValue {
    NSInteger index = [_view indexOfSelectedItem];
    if (index == -1)
        return self.defaultValue;
    return [[_items objectAtIndex:index] objectForKey:@"Id"];
}

- (NSInteger)indexOfItemWithIdentifier:(NSString *)itemIdentifier {
    NSInteger index = 0;
    for (NSDictionary *itemInfo in _items) {
        if ([[itemInfo objectForKey:@"Id"] isEqualToString:itemIdentifier]) {
            return index;
        }
        ++index;
    }
    return -1;
}

- (void)renderControlWithBuilder:(UIBuilder *)builder {
    _view = [builder addPopUpButton];
    [_view addItemsWithTitles:[_items valueForKeyPath:@"Title"]];
    [_view selectItemAtIndex:[self indexOfItemWithIdentifier:self.currentValue]];
}

- (NSArray *)currentCompilerArguments {
    NSInteger index = [self indexOfItemWithIdentifier:self.currentValue];
    id arg = nil;
    if (index >= 0) {
        arg = [[_items objectAtIndex:index] objectForKey:@"Argument"];
    }
    if ([arg isKindOfClass:[NSArray class]])
        return arg;
    else if ([arg isKindOfClass:[NSString class]])
        return [arg componentsSeparatedByString:@" "];
    else
        return [NSArray array];
}

@end



#pragma mark - Edit

@implementation EditToolOption {
    NSString              *_placeholder;

    NSTextField           *_view;
}

- (void)parse {
    _placeholder = [[_info objectForKey:@"Placeholder"] copy];
}

- (id)defaultValue {
    return @"";
}

- (id)newValue {
    return _view.stringValue;
}

- (void)renderControlWithBuilder:(UIBuilder *)builder {
    _view = [builder addTextField];
    if (_placeholder.length > 0) {
        [_view.cell setPlaceholderString:_placeholder];
    }
    _view.stringValue = self.currentValue;
}

- (NSArray *)currentCompilerArguments {
    if ([[_info objectForKey:@"SkipIfEmpty"] boolValue] && [self.currentValue length] == 0)
        return [NSArray array];

    NSDictionary *data = [NSDictionary dictionaryWithObject:self.currentValue forKey:@"$(value)"];
    id arg = [_info objectForKey:@"Argument"];
    if ([arg isKindOfClass:[NSArray class]])
        return [arg arrayBySubstitutingValuesFromDictionary:data];
    else if ([arg isKindOfClass:[NSString class]])
        return [[arg componentsSeparatedByString:@" "] arrayBySubstitutingValuesFromDictionary:data];
    else
        return [NSArray array];
}

@end
