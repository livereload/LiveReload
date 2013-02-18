
#include "nodeapp_private.h"

#include <fcntl.h>
#include <unistd.h>

void nodeapp_init_logging() {
    int fd = open(nodeapp_log_file, O_WRONLY | O_CREAT | O_TRUNC, 0664);
    dup2(fd, 2);
    close(fd);
}
