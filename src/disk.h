#ifndef __DISK_H__
#define __DISK_H__
#include <stdint.h>

void disk_read(uint32_t lsa, uint32_t *data);
void disk_write(uint32_t lsa, uint32_t *data);
void disk_flush(void);
void disk_recovery(void);

#endif /* __DISK_H__ */
