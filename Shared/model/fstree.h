
#ifndef LiveReload_fstree_h
#define LiveReload_fstree_h

typedef struct fstree_t fstree_t;
typedef struct fstree_diff_t fstree_diff_t;

fstree_t *fstree_create(const char *path);
void fstree_free(fstree_t *tree);

fstree_diff_t *fstree_diff(fstree_t *prev, fstree_t *current);
int fstree_diff_count(fstree_diff_t *diff);
const char *fstree_diff_get(int index);
void fstree_diff_free(fstree_diff_t *diff);

void fstree_dump(fstree_t *tree);

#endif

