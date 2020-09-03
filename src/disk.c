#include "ftl.h"

void disk_read(uint32_t lsa, uint32_t *data)
{
    ftl_read(lsa, data);
}

void disk_write(uint32_t lsa, uint32_t *data)
{
    ftl_write(lsa, data);

    for (int i = 0; i < 4; i++)
        ftl_gc_copy();
}

void disk_flush(void)
{
    while (!ftl_flush_precond_holds())
        ftl_gc_copy();

    ftl_flush();
}

void disk_recovery(void)
{
    ftl_recovery();

    for (int i = 0; i < 2000; i++) {
        ftl_gc_erase();
    }
}
