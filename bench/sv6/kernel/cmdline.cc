#include "types.h"
#include "kernel.hh"
#include "mmu.h"
#include "amd64.h"
#include "spinlock.hh"
#include "condvar.hh"
#include "fs.h"
#include "file.hh"
#include "major.h"

extern char cmdline[];

static int
cmdlineread(mdev*, char *dst, u32 off, u32 n)
{
  u32 cc;

  if (off >= strlen(cmdline))
    return 0;

  cc = MIN(n, strlen(cmdline)-off);
  memcpy(dst, &cmdline[off], cc);
  return cc;
}

void
initcmdline(void)
{
  if (VERBOSE)
    cprintf("cmdline: %s\n", cmdline);

  devsw[MAJ_CMDLINE].pread = cmdlineread;
}
