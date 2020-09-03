#include "types.h"
#include "defs.h"
#include "param.h"
#include "spinlock.h"
#include "fs.h"
#include "buf.h"
#ifdef FUSEFS
#include "string.h"
#endif

// Simple logging that allows concurrent FS system calls.
//
// A log transaction contains the updates of multiple FS system
// calls. The logging system only commits when there are
// no FS system calls active. Thus there is never
// any reasoning required about whether a commit might
// write an uncommitted system call's updates to disk.
//
// A system call should call begin_op()/end_op() to mark
// its start and end. Usually begin_op() just increments
// the count of in-progress FS system calls and returns.
// But if it thinks the log is close to running out, it
// sleeps until the last outstanding end_op() commits.
//
// The log is a physical re-do log containing disk blocks.
// The on-disk log format:
//   header block, containing sector #s for block A, B, C, ...
//   block A
//   block B
//   block C
//   ...
// Log appends are synchronous.

// Contents of the header block, used for both the on-disk header block
// and to keep track in memory of logged sector #s before commit.
struct logheader {
  int n;   
  int sector[LOGSIZE];
};

struct log {
  struct spinlock lock;
  int start;
  int size;
  int outstanding; // how many FS sys calls are executing.
  int committing;  // in commit(), please wait.
  int dev;
  struct logheader lh;
};

struct log thelog;

static void commit();

void
initlog(void)
{
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&thelog.lock, "log");
  readsb(ROOTDEV, &sb);

  thelog.start = sb.size - sb.nlog;
  thelog.size = sb.nlog;
  thelog.dev = ROOTDEV;
  thelog.lh.n = 0;
}

// called at the start of each FS system call.
void
begin_op(void)
{
  acquire(&thelog.lock);
  while(1){
    if(thelog.committing){
      sleep(&thelog, &thelog.lock);
    } else if(thelog.lh.n + (thelog.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
      // this op might exhaust log space; wait for commit.
      sleep(&thelog, &thelog.lock);
    } else {
      thelog.outstanding += 1;
      release(&thelog.lock);
      break;
    }
  }
}

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
  int do_commit = 0;

  acquire(&thelog.lock);
  thelog.outstanding -= 1;
  if(thelog.committing)
    panic("thelog.committing");
  if(thelog.outstanding == 0){
    do_commit = 1;
    thelog.committing = 1;
  } else {
    // begin_op() may be waiting for log space.
    wakeup(&thelog);
  }
  release(&thelog.lock);

  if(do_commit){
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.
    commit();
    acquire(&thelog.lock);
    thelog.committing = 0;
    wakeup(&thelog);
    release(&thelog.lock);
  }
}

// Copy modified blocks from cache to thelog.
static void 
write_log(void)
{
  int tail;

  for (tail = 0; tail < thelog.lh.n; tail++) {
    // struct buf *to = bread(thelog.dev, thelog.start+tail+1); // log block
    struct buf *from = bread(thelog.dev, thelog.lh.sector[tail]); // cache block
    // memmove(to->data, from->data, BSIZE);
    // bwrite(to);  // write the log
    bwrite(from);
    brelse(from); 
    // brelse(to);
  }
}

static void
commit()
{
  static int acc_commit = 0;
  if(thelog.lh.n > 0) {
    write_log();
    acc_commit++;
  }
  thelog.lh.n = 0;
  if(acc_commit == 200) {
    acc_commit = 0;
    ideflush();
  }

}

// Caller has modified b->data and is done with the buffer.
// Record the block number and pin in the cache with B_DIRTY.

// ******************************************
// commit()/write_log() will do the disk write.
// ******************************************
// log_write() replaces bwrite(); a typical use is:
//   bp = bread(...)
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
  int i;

  if (thelog.outstanding < 1)
    panic("log_write outside of trans");

  for (i = 0; i < thelog.lh.n; i++) {
    if (thelog.lh.sector[i] == b->sector)   // log absorbtion
      break;
  }
  thelog.lh.sector[i] = b->sector;
  if (i == thelog.lh.n)
    thelog.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
}

