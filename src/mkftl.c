#include <stdio.h>
#include "ftl.h"
#include "flash.h"

int main(void)
{
    printf("[mkftl] Formating flash starts.\n");
    flash_init();
    ftl_format();
    flash_fini();
    printf("[mkftl] Formating flash ends.\n");
}
