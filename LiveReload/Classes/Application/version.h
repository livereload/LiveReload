#ifndef LiveReload_version_h
#define LiveReload_version_h

#if defined(LRLegacy) && (LRLegacy == 106)

#include "version_legacy.h"

#elif defined(APPSTORE)

#include "version_mas.h"

#else

#define LIVERELOAD_VERSION "2.3.84"

#endif

#endif
