#ifndef __FTL_H__
#define __FTL_H__

#include <stdint.h>

/* FTL operations */
void ftl_read(uint32_t lsa, uint32_t *data);
void ftl_write(uint32_t lsa, uint32_t *data);
void ftl_flush(void);
void ftl_gc_copy(void);
void ftl_gc_erase(void);
void ftl_recovery(void);
void ftl_format(void);

/* FTL predicates (no side-effect) */
int ftl_flush_precond_holds(void);

#endif /* __FTL_H__ */
