#ifndef __FSEventsFix__
#define __FSEventsFix__

/*
 * See the discussion at https://github.com/thibaudgg/rb-fsevent/issues/10 about
 * the problem this library solves, and how it came to exist.
 */

char *FSEventsFix_realpath(const char *path, char *inresolved);

void FSEventsFixApply();
int FSEventsFixIsApplied();

#endif
