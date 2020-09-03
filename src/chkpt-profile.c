#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <assert.h>
#include <string.h>
#include <sys/time.h>
#include "flash.h"

void create_full_chkpt(void);
void delete_full_chkpt(void);
void delete_all_delta_chkpts(void);

static void chkpt_profile(void)
{
    uint64_t usec;
    struct timeval start, end;

    gettimeofday(&start, NULL);
    create_full_chkpt();
    gettimeofday(&end, NULL);
    usec = (end.tv_sec - start.tv_sec) * 1000000 +
           (end.tv_usec - start.tv_usec);
    fprintf(stderr, "Create full checkpoint takes %lu usecs.\n", usec);
    flash_sync();

    gettimeofday(&start, NULL);
    delete_full_chkpt();
    gettimeofday(&end, NULL);
    usec = (end.tv_sec - start.tv_sec) * 1000000 +
           (end.tv_usec - start.tv_usec);
    fprintf(stderr, "Delete full checkpoint takes %lu usecs.\n", usec);
    flash_sync();

    gettimeofday(&start, NULL);
    delete_all_delta_chkpts();
    gettimeofday(&end, NULL);
    usec = (end.tv_sec - start.tv_sec) * 1000000 +
           (end.tv_usec - start.tv_usec);
    fprintf(stderr, "Delete all delta checkpoints takes %lu usecs.\n", usec);
    flash_sync();
}


int main(void)
{
    printf("[test] Hello test!\n");
    flash_init();

    chkpt_profile();

    flash_fini();
}
