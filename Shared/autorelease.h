
#ifndef LiveReload_automem_h
#define LiveReload_automem_h

void *autorelease(void *ptr);
void autorelease_cleanup();

#define AU(val) ((__typeof(val)) autorelease(val))

#endif
