#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <assert.h>
#include <string.h>
#include <pthread.h>
#include <time.h>
#include "disk.h"
#include "flash.h"

#define PAGE_SIZE   8192
#define SECTOR_SIZE 4096
#define LSA_RANGE   (1024 * 1024 - 1)    /* 4 GiB */

static uint32_t vlt[LSA_RANGE];
static uint32_t stb[LSA_RANGE];
static uint32_t wcnt;

static uint32_t buf[SECTOR_SIZE / 4];
static uint32_t lsa_wr, data_wr;
static uint64_t n_write, n_flush, n_recovery;
static uint64_t n_cmp;
static uint64_t n_crash;

static void spec_init(void)
{
    for (uint32_t lsa = 0; lsa < LSA_RANGE; lsa++)
        stb[lsa] = -1;
}

static void spec_recovery(void)
{
    for (uint32_t lsa = 0; lsa < LSA_RANGE; lsa++)
        vlt[lsa] = stb[lsa];
    wcnt = 0;
}

static void spec_write(void)
{
    if (wcnt < 2048) {
        vlt[lsa_wr] = data_wr;
        wcnt++;
    }
}

static void spec_flush(void)
{
    for (uint32_t lsa = 0; lsa < LSA_RANGE; lsa++)
        stb[lsa] = vlt[lsa];
    wcnt = 0;
}

static uint32_t spec_read(uint32_t lsa)
{
    return vlt[lsa];
}

static void *impl_recovery(void *opaque)
{
    disk_recovery();

    return 0;
}

static void *impl_write(void *opaque)
{
    buf[0] = data_wr;
    disk_write(lsa_wr, buf);

    return 0;
}

static void *impl_flush(void *opaque)
{
    disk_flush();

    return 0;
}

static uint32_t impl_read(uint32_t lsa)
{
    disk_read(lsa, buf);
    return buf[0];
}

static void match_vlt(void)
{
    int diff = 0;

    for (uint32_t lsa = 0; lsa < LSA_RANGE; lsa++) {
        if (spec_read(lsa) != impl_read(lsa)) {
            diff = 1;
            break;
        }
    }

    if (!diff) {
        //printf("[crash-test] crash after stable changed\n");
        spec_flush();
    } else {
        //printf("[crash-test] crash before stable changed\n");
    }
}

static void compare_spec_impl(void)
{
    for (uint32_t lsa = 0; lsa < LSA_RANGE; lsa++) {
        assert(spec_read(lsa) == impl_read(lsa));
    }
}

#define OP_RECOVERY         0
#define OP_WRITE            1
#define OP_FLUSH            2

extern int crash_sim;
extern int crash_ratio;
int wr_ratio = 100;
int cmp_ratio = 200000;
int duration = 120;   /* seconds */
time_t begin, current;

int choose_write_or_flush(void)
{
    if (rand() % wr_ratio == 0)
        return OP_FLUSH;
    return OP_WRITE;
}

int main(int argc, char *argv[])
{
    if (argc != 5) {
        fprintf(stderr, "usage: ./crash-test <crash> <wr> <cmp> <duration>\n");
        return 1;
    }

    crash_ratio = atoi(argv[1]);
    wr_ratio = atoi(argv[2]);
    cmp_ratio = atoi(argv[3]);
    duration = atoi(argv[4]) * 60;

    printf("[crash-test] Hello crash! crash = %d wr = %d cmp = %d\n",
            crash_ratio, wr_ratio, cmp_ratio);

    spec_init();
    flash_init();
    crash_sim = 1;

    int crashed = 1;
    int op;
    pthread_t pthd;
    int *ret_p;

    begin = time(NULL);
    while (1) {
        if (crashed)
            op = OP_RECOVERY;
        else
            op = choose_write_or_flush();
        switch (op) {
        case OP_RECOVERY:
            n_recovery++;
            pthread_create(&pthd, NULL, impl_recovery, NULL);
            pthread_join(pthd, (void *)&ret_p);
            if (ret_p == NULL) {
                if (crashed == OP_FLUSH)
                    match_vlt();
                spec_recovery();
                crashed = 0;
            }
            break;
        case OP_WRITE:
            n_write++;
            lsa_wr = rand() % LSA_RANGE;
            data_wr = rand();
            pthread_create(&pthd, NULL, impl_write, NULL);
            pthread_join(pthd, (void *)&ret_p);
            if (ret_p == NULL) {
                spec_write();
            } else {
                crashed = OP_WRITE;
            }
            break;
        case OP_FLUSH:
            n_flush++;
            pthread_create(&pthd, NULL, impl_flush, NULL);
            pthread_join(pthd, (void *)&ret_p);
            if (ret_p == NULL) {
                spec_flush();
            } else {
                crashed = OP_FLUSH;
            }
            break;
        }

        if (rand() % cmp_ratio == 0 && !crashed) {
            compare_spec_impl();
            n_cmp++;
        }

        current = time(NULL);
        if ((current - begin) > duration) {
            printf("Simulated %lu writes, %lu flushes, and %lu crashes.\n",
                    n_write, n_flush, n_recovery);
            printf("Pass all %lu times of comparison.\n", n_cmp);
            return 0;
        }
    }

}
