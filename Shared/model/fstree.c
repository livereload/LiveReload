
#include "fstree.h"
#include "common.h"
#include "sglib.h"

#include <windows.h>
#include <sys/stat.h>
#include <stdio.h>


enum { MAXitems = 100000 };


typedef struct item_t {
  char *name;
  int parent;
#ifdef _MSC_VER
  DWORD attr;
  FILETIME write_time;
#else
  mode_t st_mode;
  dev_t st_dev;
  ino_t st_ino;
  struct timespec st_mtimespec;
  struct timespec st_ctimespec;
  off_t st_size;
#endif
} item_t;

struct fstree_t {
  item_t *items;
  int count;
};

struct fstree_diff_t {
};


void fill_item(item_t *item, WIN32_FIND_DATA *data) {
  item->attr = data->dwFileAttributes;
  item->write_time = data->ftLastWriteTime;
}

#ifdef _MSC_VER
#define ITEM_IS_DIR(item) (item->attr & FILE_ATTRIBUTE_DIRECTORY)
#else
#define ITEM_IS_DIR(item) (item->st_mode == S_IFDIR)
#endif

#define ITEM_COMPARATOR(a,b) strcmp(a.name, b.name)


fstree_t *fstree_create(const char *root_path) {
  fstree_t *tree = (fstree_t *)malloc(sizeof(fstree_t));
  item_t *items = tree->items = (item_t *)calloc(MAXitems, sizeof(item_t));
  tree->count = 0;

  /* struct stat st; */
  WIN32_FIND_DATA st;
  HANDLE hFind;
  WCHAR buf[MAX_PATH], buf2[MAX_PATH];
  char utf_buf[MAX_PATH * 3];

  hFind = FindFirstFile(U2W(root_path), &st);
  if (hFind == INVALID_HANDLE_VALUE)
    goto fin;
  FindClose(hFind);
  {
      struct item_t *item = &items[tree->count++];
      item->name = strdup("");
      fill_item(item, &st);
  }

  for (int next = 0; next < tree->count; ++next) {
    struct item_t *item = &items[next];
    if (ITEM_IS_DIR(item)) {
//                    NSLog(@"Listing %@", item->name);
      _u2w(buf, MAX_PATH, root_path);
      if (*item->name) {
        _u2w(buf2, MAX_PATH, item->name);
        wcscat(buf, L"\\");
        wcscat(buf, buf2);
      }
      wcscat(buf, L"\\*.*");

      hFind = FindFirstFile(buf, &st);
      if (hFind != INVALID_HANDLE_VALUE) {
        int first = tree->count;
        do {
          if (TRUE) {
              if (0 == wcscmp(st.cFileName, L".") || 0 == wcscmp(st.cFileName, L".."))
                  continue;

            struct item_t *subitem = &items[tree->count++];
            subitem->parent = next;

            char *name = w2u(st.cFileName);
            if (*item->name) {
              strcpy(utf_buf, item->name);
              strcat(utf_buf, "\\");
              strcat(utf_buf, name);
            } else {
              strcpy(utf_buf, name);
            }
            free(name);

            subitem->name = strdup(utf_buf);
            fill_item(subitem, &st);
          }
        } while (FindNextFile(hFind, &st));
        FindClose(hFind);

        SGLIB_ARRAY_QUICK_SORT(item_t, (tree->items + first), (tree->count - first), ITEM_COMPARATOR, SGLIB_ARRAY_ELEMENTS_EXCHANGER);
      }
    }
  }
fin:
  return tree;
}

void fstree_free(fstree_t *tree) {

}

void fstree_dump(fstree_t *tree) {
  printf("Tree with %d items:\n", tree->count);
  for (int i = 0; i < tree->count; ++i) {
    printf(" %2d) %s\n", i, tree->items[i].name);
  }
}



/* fstree_diff_t *fstree_diff(fstree_t *prev, fstree_t *current); */
/* int fstree_difftree->count(fstree_diff_t *diff); */
/* const char *fstree_diff_get(int index); */
/* void fstree_diff_free(fstree_diff_t *diff); */

