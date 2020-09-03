#include <stdint.h>

__attribute__((noinline, optnone))
void flash_read(uint32_t blkid, uint32_t pgid, uint32_t *data)
{
}

__attribute__((noinline, optnone))
void flash_read_bulk(uint32_t blkid, uint32_t nblks, uint32_t *data)
{
}

__attribute__((noinline, optnone))
void flash_program(uint32_t blkid, uint32_t pgid, uint32_t *data, uint32_t sync)
{
}

__attribute__((noinline, optnone))
void flash_program_bulk(uint32_t blkid, uint32_t nblks, uint32_t *data)
{
}

__attribute__((noinline, optnone))
void flash_erase(uint32_t blkid, uint32_t sync)
{
}

__attribute__((noinline, optnone))
void flash_erase_bulk(uint32_t blkid, uint32_t nblks)
{
}

__attribute__((noinline, optnone))
void flash_sync(void)
{
}
