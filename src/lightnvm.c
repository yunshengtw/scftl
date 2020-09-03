#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <liblightnvm.h>
#include "flash.h"

#define NUM_PHYSICAL_BLOCKS     4096 /* Assume a 8 GiB SSD */
#define PAGES_PER_BLOCK         256
#define PAGE_SIZE               8192
#define SECTOR_SIZE             4096
#define SECTORS_PER_PAGE        2

static int depth = 256; 
static int cnt_asyc_op = 0;
static uint32_t *write_buf;
static uint32_t *read_buf;
static struct nvm_dev *dev;
static int pmode;
static struct nvm_async_ctx *ctx;
static struct nvm_ret write_ret = { 0 };
static struct nvm_ret read_ret = { 0 };
static void callback(struct nvm_ret *ret, void *cb_arg){ }

void flash_read(uint32_t blkid, uint32_t pgid, uint32_t *data)
{
    assert(dev != NULL);
    assert(read_buf != NULL);
    uint32_t ppa = blkid * PAGES_PER_BLOCK + pgid;
    struct nvm_addr arr[SECTORS_PER_PAGE];
    uint32_t offset = ppa * SECTORS_PER_PAGE;
    for(int i = 0; i < SECTORS_PER_PAGE; i++) {
        arr[i] = nvm_addr_dev2gen(dev, offset + i);
    }
    int err = nvm_cmd_read(dev, arr, SECTORS_PER_PAGE, read_buf, NULL, NVM_CMD_SCALAR|NVM_CMD_SYNC, &write_ret);
    //ssize_t res = nvm_async_wait(dev, ctx);

    if(err) {
        memset(data, 0xff, PAGE_SIZE);
        return;
    }
    memcpy(data, read_buf, PAGE_SIZE);
}

void flash_read_bulk(uint32_t blkid, uint32_t nblks, uint32_t *data)
{
    printf("[lightnvm] read_bulk @ %u, nblks = %u\n", blkid, nblks);
    for (uint32_t b = blkid; b < blkid + nblks; b++) {
        for (uint32_t p = 0; p < PAGES_PER_BLOCK; p++) {
            flash_read(b, p, &(data[((b - blkid) * PAGES_PER_BLOCK + p) * (PAGE_SIZE / 4)]));
        }
    }
}

void flash_program(uint32_t blkid, uint32_t pgid, uint32_t *data, uint32_t sync)
{
    uint32_t ppa = blkid * PAGES_PER_BLOCK + pgid;

    assert(sync < 2);
    assert(dev != NULL);
    assert(write_buf != NULL);
    
    printf("[lightnvm] program @ (%u, %u), sync = %u\n", blkid, pgid, sync);
    
    if(cnt_asyc_op && (cnt_asyc_op % depth) == 0) {
        ssize_t res = nvm_async_wait(dev, ctx);
        if (res < 0) 
            perror("nvm_async_wait fail");
#ifdef DEBUG
        printf("DEBUG: page_program trigger sync_flush\n");
        printf("# nvm_async_wait -- done, res: %zd\n", res);
#endif
    }

    struct nvm_addr page_addr[SECTORS_PER_PAGE];
    uint32_t offset = ppa * SECTORS_PER_PAGE;
    
    for(int i = 0; i < SECTORS_PER_PAGE; i++) { 
        page_addr[i] = nvm_addr_dev2gen(dev, offset + i);
        assert(!nvm_addr_check(page_addr[i], dev));
    }
    memcpy(write_buf, data, PAGE_SIZE);
    int err = nvm_cmd_write(dev, page_addr, SECTORS_PER_PAGE, write_buf, NULL, NVM_CMD_SCALAR|(NVM_CMD_ASYNC*(!sync)+NVM_CMD_SYNC*sync), &write_ret);

#ifdef DEBUG
    printf("DEBUG: flash page_program %d\n", ppa);
#endif 

    if(err) {
        perror("flash: nvm_cmd_write fail");
    }
    if(!sync)
        cnt_asyc_op++;
}

void flash_program_bulk(uint32_t blkid, uint32_t nblks, uint32_t *data)
{
    printf("[lightnvm] program_bulk @ %u, nblks = %u\n", blkid, nblks);
    for (uint32_t b = blkid; b < blkid + nblks; b++) {
        for (uint32_t p = 0; p < PAGES_PER_BLOCK; p++) {
            flash_program(b, p, &(data[((b - blkid) * PAGES_PER_BLOCK + p) * (PAGE_SIZE / 4)]), 0);
        }
    }
}

void flash_erase(uint32_t blkid, uint32_t sync)
{
    printf("[lightnvm] erase @ %u, sync = %u\n", blkid, sync);
    assert(dev != NULL);
    struct nvm_ret ret = { 0 };
    struct nvm_addr block = nvm_addr_dev2gen(dev, blkid * PAGES_PER_BLOCK * SECTORS_PER_PAGE);
    assert(!nvm_addr_check(block, dev));
    int err = nvm_cmd_erase(dev, &block, 1, NULL, pmode, &ret);
    if (err) {
        printf("FAIL");
        perror("nvm_cmd_erase");
        exit(-1);
    }
}

void flash_erase_bulk(uint32_t blkid, uint32_t nblks)
{
    printf("[lightnvm] erase_bulk @ %u, nblks = %u\n", blkid, nblks);
    for (uint32_t b = blkid; b < blkid + nblks; b++) {
        flash_erase(b, 1);
    }
//    printf("[lightnvm] erase_bulk @ %u, nblks = %u\n", blkid, nblks);
//  struct nvm_ret ret = { 0 };
//  struct nvm_addr *block_arr = (struct nvm_addr*)malloc(sizeof(struct nvm_addr)*nblks);
//  // begin of each blk address(in sector format) 
//  for(uint32_t i = 0; i < nblks; i++) {
//      block_arr[i] = nvm_addr_dev2gen(dev, (blkid + i) * PAGES_PER_BLOCK * SECTORS_PER_PAGE);
//      assert(!nvm_addr_check(block_arr[i], dev));
//  }
//  int err = nvm_cmd_erase(dev, &(block_arr[0]), nblks, NULL, pmode, &ret);
//  if (err) {
//      printf("FAIL");
//      perror("nvm_cmd_erase");
//      return -1;
//  }
}

void flash_sync(void)
{
    printf("[lightnvm] sync\n");
    ssize_t res = nvm_async_wait(dev, ctx);
    if (res < 0) {
        perror("flash: nvm_async_wait fail");
        printf("# nvm_async_term\n");
        if (nvm_async_term(dev, ctx)) {
            perror("# nvm_async_term");
            return;
        }
    }
}

void flash_init(void)
{
    printf("[lightnvm] lightnvm flash_init starts.\n");
    if(dev == NULL) {
        dev = nvm_dev_openf("/dev/nvme0n1", 0x2);
    }
    assert(nvm_dev_get_be_id(dev) == 2);
    if(!dev) {
        perror("flash: nvm_dev_open fail");
        return;
    }

    pmode = nvm_dev_get_pmode(dev);

    ctx = nvm_async_init(dev, depth, 0x0);
    if (!ctx) {
        perror("could not initialize async context");
        return;
    }
    write_ret.async.ctx = ctx;
    write_ret.async.cb = callback;
    write_ret.async.cb_arg = NULL;

    if(write_buf == NULL) {
        write_buf = nvm_buf_alloc(dev, PAGE_SIZE, NULL);
        read_buf = nvm_buf_alloc(dev, PAGE_SIZE, NULL);
    }
    printf("[lightnvm] lightnvm flash_init ends.\n");
}

void flash_fini(void)
{       
    printf("[lightnvm] lightnvm flash_fini starts.\n");
    flash_sync();
    nvm_buf_free(dev, read_buf);
    nvm_buf_free(dev, write_buf);
    nvm_dev_close(dev);
    printf("[lightnvm] lightnvm flash_fini ends.\n");
}

