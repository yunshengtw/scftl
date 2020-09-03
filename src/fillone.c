#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "flash.h"

#define BLOCKS_DELTA    512
#define PAGES_PER_BLOCK 256
#define PAGE_SIZE       8192

static uint32_t buf[PAGE_SIZE / 4];

int main(int argc, char *argv[])
{
    if (argc != 2) {
        fprintf(stderr, "usage: ./fillone <blks>\n");
        return 1;
    }
    uint32_t n_erased;
    n_erased = atoi(argv[1]);
    if (n_erased > BLOCKS_DELTA) {
        fprintf(stderr, "Too much blocks.\n");
        return 1;
    }

    printf("[fillone] Filling delta chkpt with one starts.\n");
    flash_init();
    memset(buf, 0xff, PAGE_SIZE);
    for (uint32_t b = 0; b < n_erased; b++)
        for (uint32_t p = 0; p < PAGES_PER_BLOCK; p++)
            flash_program(b, p, buf, 0);
    flash_fini();
    printf("[fillone] Filling delta chkpt with one ends.\n");
}
