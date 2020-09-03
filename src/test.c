#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <assert.h>
#include <string.h>
#include <sys/time.h>
#include "disk.h"
#include "flash.h"

#define PAGE_SIZE   8192
#define LSA_RANGE   (1024 * 1024 - 1)    /* 4 GiB */

static uint32_t data[PAGE_SIZE / 4];

static void random_write_4k(void)
{
    uint32_t lsa = rand() % LSA_RANGE;
    data[0] = lsa;
    printf("[test] write @ %u\n", lsa);
    disk_write(lsa, data);
}

static void test_random_write_4k_epoch(uint32_t n_epoch)
{
    uint64_t usec;
    struct timeval start, end;
    gettimeofday(&start, NULL);
    for (uint32_t i = 0; i < n_epoch; i++) {
        for (uint32_t j = 0; j < 1000; j++)
            random_write_4k();
        disk_flush();
    }
    gettimeofday(&end, NULL);
    usec = (end.tv_sec - start.tv_sec) * 1000000 + (end.tv_usec - start.tv_usec);
    printf("Execution time time = %lu\n", usec);
}

static void test_random_write_4k_loop(void)
{
    while (1) {
        for (uint32_t i = 0; i < 1000; i++)
            random_write_4k();
        disk_flush();
    }
}

static void test_write_and_read(void)
{
    uint32_t lsas[10];
    static uint32_t data_wr[PAGE_SIZE / 4];
    static uint32_t data_rd[PAGE_SIZE / 4];

    for (uint32_t i = 0; i < 10; i++)
        lsas[i] = rand() % LSA_RANGE;

    for (uint32_t i = 0; i < 10; i++) {
        data_wr[0] = lsas[i];
        disk_write(lsas[i], data_wr);
        disk_read(lsas[i], data_rd);
        assert(data_rd[0] == lsas[i]);
    }

    for (uint32_t i = 0; i < 10; i++) {
        disk_read(lsas[i], data_rd);
        assert(data_rd[0] == lsas[i]);
    }

    printf("[test] Pass test_write_and_read.\n");
}

static void pair_write(void)
{
    uint32_t lsas[10];
    static uint32_t data_wr[PAGE_SIZE / 4];

    for (uint32_t i = 0; i < 10; i++)
        lsas[i] = (i * 30) % LSA_RANGE;

    for (uint32_t i = 0; i < 10; i++) {
        data_wr[0] = lsas[i];
        data_wr[1] = lsas[i]+1;
        disk_write(lsas[i], data_wr);
    }
}

static void pair_read(void)
{
    uint32_t lsas[10];
    uint32_t data_rd[PAGE_SIZE / 4];

    for (uint32_t i = 0; i < 10; i++)
        lsas[i] = (i * 30) % LSA_RANGE;

    for (uint32_t i = 0; i < 10; i++) {
        disk_read(lsas[i], data_rd);
        assert(data_rd[0] == lsas[i]);
        assert(data_rd[1] == lsas[i]+1);
    }

    printf("[test] Pass pair_read.\n");
}

int main(int argc, char* argv[])
{

    // test re-open consistency
    if (argc != 2) {
        printf("./test <option: pair_write(1) pair_read(2)>\n");
        exit(-1);
    }
    printf("[test] Hello test!\n");
    flash_init();
    disk_recovery();
    printf("[test] Disk recovery done.\n");

    //test_random_write_4k_loop();
    //test_write_and_read();
    if (strcmp(argv[1], "1") == 0) {
        printf("test write\n");
        pair_write();
    } else if (strcmp(argv[1], "2") == 0) {
        printf("test read\n");
        pair_read();
    } else if (strcmp(argv[1], "3") == 0) {
        test_random_write_4k_epoch(10);
    } else {
        printf("no support for the input\n");
    }
    disk_flush();
    flash_fini();
}
