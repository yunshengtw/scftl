#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#define SECTOR_SIZE 4096

int devfd;

void disk_read(uint32_t lsa, uint32_t *data)
{
    ssize_t ret;

    //ret = read(devfd, data, SECTOR_SIZE);
    ret = pread(devfd, data, SECTOR_SIZE, lsa * SECTOR_SIZE);
    if (ret != SECTOR_SIZE) {
        perror("Fail to pread /dev/nvme0n1-pblk");
        exit(1);
    }
}

void disk_write(uint32_t lsa, uint32_t *data)
{
    ssize_t ret;

    //ret = write(devfd, data, SECTOR_SIZE);
    ret = pwrite(devfd, data, SECTOR_SIZE, lsa * SECTOR_SIZE);
    if (ret != SECTOR_SIZE) {
        perror("Fail to pwrite /dev/nvme0n1-pblk");
        exit(1);
    }
}

void disk_flush(void)
{
    int ret;

    ret = fsync(devfd);
    if (ret == -1) {
        perror("Fail to fsync /dev/nvme0n1-pblk");
        exit(1);
    }
}

void disk_recovery(void)
{
    devfd = open("/dev/nvme0n1-pblk", O_RDWR);
    if (devfd == -1) {
        perror("Fail to open /dev/nvme0n1-pblk");
        exit(1);
    }
}

void flash_init(void)
{
}

void flash_fini(void)
{
}
