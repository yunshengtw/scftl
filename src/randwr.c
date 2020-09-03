#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <assert.h>
#include <string.h>
#include <sys/time.h>
#include "disk.h"
#include "flash.h"

#define PAGE_SIZE   8192
#define SECTOR_SIZE 4096
#define LSA_RANGE   (16 * 1024 - 1)    /* 64 MiB */

static uint32_t data[SECTOR_SIZE / 4];

static void random_write_4k(void)
{
    uint32_t lsa = rand() % LSA_RANGE;
    data[0] = lsa;
    printf("[test] write @ %u\n", lsa);
    disk_write(lsa, data);
}

static void sequential_write_4k(void)
{
    static uint32_t lsa_seq = 0;
    if (lsa_seq == LSA_RANGE)
        lsa_seq = 0;
    data[0] = lsa_seq;
    printf("[test] write @ %u\n", lsa_seq);
    disk_write(lsa_seq++, data);
}

static void random_write_4k_loop(int wr_interval)
{
    uint64_t usec;
    struct timeval start, end;
    uint64_t epoch = 0;
    uint64_t wr_in_one_epoch = 0;
    int should_flush = 1;
    if (wr_interval == -1) {
        wr_interval = 2000;
        should_flush = 0;
    }
    gettimeofday(&start, NULL);
    while (epoch < 3) {
        for (int j = 0; j < wr_interval; j++) {
            random_write_4k();
            wr_in_one_epoch++;
            gettimeofday(&end, NULL);
            usec = (end.tv_sec - start.tv_sec) * 1000000 +
                   (end.tv_usec - start.tv_usec);
            if (usec > epoch * 10000000) {
                fprintf(stderr, "# of writes in epoch %lu = %lu\n",
                        epoch, wr_in_one_epoch);
                epoch++;
                wr_in_one_epoch = 0;
            }
        }
        if (should_flush)
            disk_flush();
    }
}

static void sequential_write_4k_loop(int wr_interval)
{
    uint64_t usec;
    struct timeval start, end;
    uint64_t epoch = 0;
    uint64_t wr_in_one_epoch = 0;
    int should_flush = 1;
    if (wr_interval == -1) {
        wr_interval = 2000;
        should_flush = 0;
    }
    gettimeofday(&start, NULL);
    while (epoch < 60) {
        for (int j = 0; j < wr_interval; j++) {
            sequential_write_4k();
            wr_in_one_epoch++;
            gettimeofday(&end, NULL);
            usec = (end.tv_sec - start.tv_sec) * 1000000 +
                   (end.tv_usec - start.tv_usec);
            if (usec > epoch * 10000000) {
                fprintf(stderr, "# of writes in epoch %lu = %lu\n",
                        epoch, wr_in_one_epoch);
                epoch++;
                wr_in_one_epoch = 0;
            }
        }
        if (should_flush)
            disk_flush();
    }
}

static void random_write_4k_10_epochs(void)
{
    uint64_t usec;
    struct timeval start, end;
    uint64_t epoch = 0;
    uint64_t wr_in_one_epoch = 0;
    gettimeofday(&start, NULL);
    for (uint32_t i = 0; i < 10; i++) {
        for (int j = 0; j < 2000; j++) {
            random_write_4k();
/*
            wr_in_one_epoch++;
            gettimeofday(&end, NULL);
            usec = (end.tv_sec - start.tv_sec) * 1000000 +
                   (end.tv_usec - start.tv_usec);
            if (usec > epoch * 5000000) {
                fprintf(stderr, "# of writes in epoch %lu = %lu\n",
                        epoch, wr_in_one_epoch);
                epoch++;
                wr_in_one_epoch = 0;
            }
*/
        }
        disk_flush();
    }
    gettimeofday(&end, NULL);
    usec = (end.tv_sec - start.tv_sec) * 1000000 +
           (end.tv_usec - start.tv_usec);
    printf("Execution time = %lu\n", usec);
}

int main(int argc, char *argv[])
{
    if (argc != 2) {
        fprintf(stderr, "usage: ./randwr-vblk <wr interval>\n");
        return 1;
    }

    int wr_interval = atoi(argv[1]);
    printf("[test] Hello test!\n");
    flash_init();
    disk_recovery();
    printf("[test] Disk recovery done.\n");

    random_write_4k_loop(wr_interval);
    //sequential_write_4k_loop(wr_interval);
    //random_write_4k_10_epochs();

    disk_flush();
    flash_fini();
}
