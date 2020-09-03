#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <pthread.h>

#define NUM_PHYSICAL_BLOCKS     2048 /* Assume a 8 GiB SSD */
#define PAGES_PER_BLOCK         512
#define PAGE_SIZE               8192
#define SECTOR_SIZE             4096

int crash_sim = 0;
int pthd_ret;
int crash_ratio = 5;

static char *flash[NUM_PHYSICAL_BLOCKS][PAGES_PER_BLOCK];
static char synced[NUM_PHYSICAL_BLOCKS][PAGES_PER_BLOCK];

static void flash_crash(void)
{
    // printf("[flashemu] flash_crash\n");
    for (uint32_t b = 0; b < NUM_PHYSICAL_BLOCKS; b++)
        for (uint32_t p = 0; p < PAGES_PER_BLOCK; p++)
            if (!synced[b][p]) {
                // printf("[flashemu] (%u, %u) not synced\n", b, p);
                free(flash[b][p]);
                flash[b][p] = malloc(PAGE_SIZE);
            }
}

void flash_read(uint32_t blkid, uint32_t pgid, uint32_t *data)
{
    // printf("[flashemu] read @ (%u, %u)\n", blkid, pgid);
    char *page = flash[blkid][pgid];

    if (page == NULL) {
        memset(data, 0xff, PAGE_SIZE);
        return;
    }
    memcpy(data, page, PAGE_SIZE);
}

void flash_read_bulk(uint32_t blkid, uint32_t nblks, uint32_t *data)
{
    // printf("[flashemu] read_bulk @ %u, nblks = %u\n", blkid, nblks);
    for (uint32_t b = blkid; b < blkid + nblks; b++) {
        for (uint32_t p = 0; p < PAGES_PER_BLOCK; p++) {
            char *page = flash[b][p];

            if (page == NULL)
                memset(&data[((b - blkid) * PAGES_PER_BLOCK + p) * (PAGE_SIZE / 4)], 0xff, PAGE_SIZE);
            else
                memcpy(&data[((b - blkid) * PAGES_PER_BLOCK + p) * (PAGE_SIZE / 4)], page, PAGE_SIZE);
        }
    }
}

void flash_program(uint32_t blkid, uint32_t pgid, uint32_t *data, uint32_t sync)
{
    if (crash_sim && sync && (rand() % crash_ratio) == 0) {
        flash_crash();
        pthd_ret = 1;
        pthread_exit(&pthd_ret);
    }

    // printf("[flashemu] program @ (%u, %u), sync = %u\n", blkid, pgid, sync);
    if (flash[blkid][pgid] == NULL)
        flash[blkid][pgid] = malloc(PAGE_SIZE);

    char *page = flash[blkid][pgid];
    memcpy(page, data, PAGE_SIZE);
    synced[blkid][pgid] = sync;
}

void flash_program_bulk(uint32_t blkid, uint32_t nblks, uint32_t *data)
{
    // printf("[flashemu] program_bulk @ %u, nblks = %u\n", blkid, nblks);
    for (uint32_t b = blkid; b < blkid + nblks; b++) {
        for (uint32_t p = 0; p < PAGES_PER_BLOCK; p++) {
            if (flash[b][p] == NULL)
                flash[b][p] = malloc(PAGE_SIZE);

            char *page = flash[b][p];
            memcpy(page, &data[((b - blkid) * PAGES_PER_BLOCK + p) * (PAGE_SIZE / 4)], PAGE_SIZE);
            synced[b][p] = 0;
        }
    }
}

void flash_erase(uint32_t blkid, uint32_t sync)
{
    if (crash_sim && sync && (rand() % crash_ratio) == 0) {
        flash_crash();
        pthd_ret = 1;
        pthread_exit(&pthd_ret);
    }

    // printf("[flashemu] erase @ %u, sync = %u\n", blkid, sync);
    for (uint32_t p = 0; p < PAGES_PER_BLOCK; p++) {
        char *page = flash[blkid][p];
        if (page != NULL)
            free(page);
            // memset(page, 0xff, PAGE_SIZE);
        flash[blkid][p] = NULL;
        synced[blkid][p] = sync;
    }
}

void flash_erase_bulk(uint32_t blkid, uint32_t nblks)
{
    // printf("[flashemu] erase_bulk @ %u, nblks = %u\n", blkid, nblks);
    for (uint32_t b = blkid; b < blkid + nblks; b++) {
        for (uint32_t p = 0; p < PAGES_PER_BLOCK; p++) {
            char *page = flash[b][p];
            if (page != NULL)
                free(page);
                // memset(page, 0xff, PAGE_SIZE);
            flash[b][p] = NULL;
            synced[b][p] = 0;
        }
    }
}

void flash_sync(void)
{
    if (crash_sim && (rand() % crash_ratio) == 0) {
        flash_crash();
        pthd_ret = 1;
        pthread_exit(&pthd_ret);
    }

    // printf("[flashemu] sync\n");
    for (uint32_t b = 0; b < NUM_PHYSICAL_BLOCKS; b++)
        for (uint32_t p = 0; p < PAGES_PER_BLOCK; p++)
            synced[b][p] = 1;
}

void flash_init(void)
{
    char *fname = "./init.img";
    FILE *fp;
    uint32_t num;
    uint32_t b, p;

    fp = fopen(fname, "r");
    if (fp == NULL) {
        fprintf(stderr, "[flashemu] Flash image %s not found. Generate a new one.\n", fname);
        return;
    }

    for (b = 0; b < NUM_PHYSICAL_BLOCKS; b++)
        for (p = 0; p < PAGES_PER_BLOCK; p++)
            flash[b][p] = NULL;

    for (b = 0; b < NUM_PHYSICAL_BLOCKS; b++)
        for (p = 0; p < PAGES_PER_BLOCK; p++)
            synced[b][p] = 1;

    fread(&num, sizeof(uint32_t), 1, fp);
    //printf("[flashemu] flash_init: Number of written pages = %u.\n", num);
    for (uint32_t i = 0; i < num; i++) {
        fread(&b, sizeof(uint32_t), 1, fp);
        fread(&p, sizeof(uint32_t), 1, fp);
        char *page = malloc(PAGE_SIZE);
        fread(page, sizeof(char), PAGE_SIZE, fp);
        flash[b][p] = page;
    }

    fclose(fp);
}

void flash_fini(void)
{
    char *fname = "./init.img";
    FILE *fp;
    uint32_t num = 0;

    fp = fopen(fname, "w");
    if (fp == NULL) {
        fprintf(stderr, "Cannot open %s\n.", fname);
        exit(1);
    }

    for (uint32_t b = 0; b < NUM_PHYSICAL_BLOCKS; b++) {
        for (uint32_t p = 0; p < PAGES_PER_BLOCK; p++) {
            char *page = flash[b][p];
            if (page != NULL) {
                num++;
            }
        }
    }

    printf("[flashemu] flash_fini: Number of written pages = %u.\n", num);
    fwrite(&num, sizeof(uint32_t), 1, fp);
    for (uint32_t b = 0; b < NUM_PHYSICAL_BLOCKS; b++) {
        for (uint32_t p = 0; p < PAGES_PER_BLOCK; p++) {
            char *page = flash[b][p];
            if (page != NULL) {
                fwrite(&b, sizeof(uint32_t), 1, fp);
                fwrite(&p, sizeof(uint32_t), 1, fp);
                fwrite(page, sizeof(char), PAGE_SIZE, fp);
            }
        }
    }

    fclose(fp);
}
