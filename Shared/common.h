
#ifndef LiveReload_common_h
#define LiveReload_common_h

#ifdef _MSC_VER
#define __typeof decltype
#endif

#define ARRAY_FOREACH(type, array, iterVar, code) {\
    type *iterVar##end = (array) + sizeof((array))/sizeof((array)[0]);\
    for(type *iterVar = (array); iterVar < iterVar##end; ++iterVar) {\
        code;\
    }\
}

#endif
