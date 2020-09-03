#ifndef __FLASHEMU_H__
#define __FLASHEMU_H__
#include <stdint.h>

/* Flash api */
void flash_read(uint32_t blkid, uint32_t pgid, uint32_t *data);
void flash_read_bulk(uint32_t blkid, uint32_t nblks, uint32_t *data);
void flash_program(uint32_t blkid, uint32_t pgid, uint32_t *data, uint32_t sync);
void flash_program_bulk(uint32_t blkid, uint32_t nblks, uint32_t *data);
void flash_erase(uint32_t blkid, uint32_t sync);
void flash_erase_bulk(uint32_t blkid, uint32_t nblks);
void flash_sync(void);

/* Save and load flash state */
void flash_init();
void flash_fini();

#endif /* __FLASHEMU_H__ */
