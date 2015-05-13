#ifndef __FSEventsFix__
#define __FSEventsFix__

/*
 * See the discussion at https://github.com/thibaudgg/rb-fsevent/issues/10 about
 * the problem this library solves, and how it came to exist.
 */

void FSEventsFixApply();
int FSEventsFixIsApplied();

#endif
