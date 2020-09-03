#include <stdio.h>
#include "flash.h"

#define PAGE_SIZE 8192

static uint32_t buf[PAGE_SIZE / 4];

int main(void)
{
    flash_init();

    flash_program(0, 0, buf, 0);
    flash_program(0, 1, buf, 0);
    flash_program(0, 2, buf, 0);
    flash_program(0, 3, buf, 0);
    flash_program(0, 4, buf, 0);
    flash_program(0, 5, buf, 0);
    flash_program(0, 6, buf, 0);
    flash_program(0, 7, buf, 0);
    flash_program(0, 8, buf, 0);
    flash_program(0, 9, buf, 0);
    flash_program(0, 10, buf, 0);
    flash_program(0, 11, buf, 0);
    flash_program(0, 12, buf, 0);
    flash_program(0, 13, buf, 0);
    flash_program(0, 14, buf, 0);
    flash_program(0, 15, buf, 0);

    flash_read(0, 0, buf);
    flash_read(0, 1, buf);
    flash_read(0, 2, buf);
    flash_read(0, 3, buf);
    flash_read(0, 4, buf);
    flash_read(0, 5, buf);
    flash_read(0, 6, buf);
    flash_read(0, 7, buf);
    flash_read(0, 8, buf);
    flash_read(0, 9, buf);
    flash_read(0, 10, buf);
    flash_read(0, 11, buf);
    flash_read(0, 12, buf);
    flash_read(0, 13, buf);
    flash_read(0, 14, buf);
    flash_read(0, 15, buf);

    flash_erase(0, 0);
    flash_erase(1, 0);

    int tmp;
    scanf("%d", &tmp);
    flash_fini();
}
