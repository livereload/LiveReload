#ifndef nodeapp_ui_objcobject_hh
#define nodeapp_ui_objcobject_hh

#import <Foundation/Foundation.h>
// #include <objc/runtime.h>


// Fakes an Objective-C class out of a C++ class.
//
// Note that this is a very bad and completely superfluous idea, but after looking up a way
// to build Objective-C classes at run time, I just had to do this no matter what. (Besides,
// I really hated maintaining mutual pointers in UIElement/UIElementDelegate class pairs.)
//
// Building up a whole class from scratch (objc_allocateClassPair) looked like a lot of trouble,
// so I compile a real Objective-C class instead, but instead of instantiating it by regular means
// (alloc/init or class_createInstance), I simply cast a part of a C++ object to (id).
// I've looked at the source code for class_createInstance and this hack should work perfectly,
// but of course we're relying on a private implementation detail of Objective-C runtime here.
//
// The beauty is that if I inherit from ObjCObject, I can let C++ figure out the pointer arithmetic
// necessary to convert between (SomeUIElement *) and (ObjCObject *, aka id).
//
// Our use case is so trivial that it makes no sense to apply any kind of tricks here. However,
// again, I couldn't help myself, and hey, it's my product, I want to have fun writing it.
class ObjCObject {
public:
    Class isa;
    // NSObject holds reference counts in a separate hashtable, so we don't need to allocate space for that

    ObjCObject(Class isa) {
        this->isa = isa;
    }

    id self() {
        return (id)this;
    }

    template <typename T>
    static T *from_id(id obj) {
        return static_cast<T *>(reinterpret_cast<ObjCObject *>(obj));
    }
protected:
    // CoreFoundation wants ObjC classes to be at least 16 bytes in length,
    void *_cf_filler[3];
};

#endif
