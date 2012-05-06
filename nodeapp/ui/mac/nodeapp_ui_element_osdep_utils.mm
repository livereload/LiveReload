
#include "nodeapp_ui_element_osdep_utils.hh"

#import <Cocoa/Cocoa.h>
#include <objc/runtime.h>


NSColor *NSColorFromStringSpec(NSString *spec) {
    NSCAssert1([spec characterAtIndex:0] == '#', @"Invalid color format: '%@'", spec);
    unsigned red, green, blue, alpha = 255;
    BOOL ok;
    switch ([spec length]) {
        case 4:
            ok = hex2i(spec, 1, 1, &red) && hex2i(spec, 2, 1, &green) && hex2i(spec, 3, 1, &blue);
            red   = (red   << 4) + red;
            green = (green << 4) + green;
            blue  = (blue  << 4) + blue;
            break;
        case 7:
            ok = hex2i(spec, 1, 2, &red) && hex2i(spec, 3, 2, &green) && hex2i(spec, 5, 2, &blue);
            break;
        case 9:
            ok = hex2i(spec, 1, 2, &red) && hex2i(spec, 3, 2, &green) && hex2i(spec, 5, 2, &blue) && hex2i(spec, 7, 2, &alpha);
            break;
        default:
            ok = NO;
            break;
    }
    NSCAssert1(ok, @"Invalid color format: '%@'", spec);
    return [NSColor colorWithCalibratedRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:alpha/255.0];
}

bool invoke_custom_func_in_nsobject(id object, const char *method, json_t *arg) {
    NSString *selectorName = [NSString stringWithFormat:@"%s:", method];
    SEL selector = NSSelectorFromString(selectorName);
    if ([object respondsToSelector:selector]) {
        if (*[[object methodSignatureForSelector:selector] getArgumentTypeAtIndex:2] == '@') {
            // accepts NSDictionary *
            [object performSelector:selector withObject:nodeapp_json_to_objc(arg, YES)];
        } else {
            // accepts json_t *; signature returned by getArgumentTypeAtIndex looks like ^{...bullshit...}
            IMP imp = [object methodForSelector:selector];
            imp(object, selector, arg);
        }
        return true;
    } else {
        return false;
    }
}

int parse_enum(const char *name, ...) {
    va_list va;
    const char *candidate;
    int index = 0;

    va_start(va, name);
    while (!!(candidate = va_arg(va, const char *))) {
        if (0 == strcmp(name, candidate))
            return index;
        ++index;
    }
    va_end(va);

    assert1(NO, "Not a valid enumeration identifier: '%s'", name);
}
