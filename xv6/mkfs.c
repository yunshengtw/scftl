#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <assert.h>

#define stat xv6_stat  // avoid clash with host struct stat
#include "types.h"
#include "stat.h"
#include "param.h"
#include "fs.h"
/* Disk interface */
#include "disk.h"
#ifndef static_assert
#define static_assert(a, b) do { switch (0) case 0: case (a): ; } while (0)
#endif

#define SIZE 100000
#define NINODES 40000

// Disk layout:
// [ boot block | sb block | inode blocks | bit map | data blocks | log ]

int nbitmap = SIZE/(BSIZE*8) + 1;
int ninodeblocks = NINODES / IPB + 1;
int nlog = LOGSIZE;  
int nmeta;    // Number of meta blocks (inode, bitmap, and 2 extra)
int nblocks;  // Number of data blocks

int fsfd;
struct superblock sb;
__attribute__((__aligned__(4))) char zeroes[BSIZE];
uint freeinode = 1;
uint freeblock;

void balloc(int);
void wsect(uint, void*);
void winode(uint, struct dinode*);
void rinode(uint inum, struct dinode *ip);
void rsect(uint sec, void *buf);
static uint ialloc(ushort type);
void iappend(uint inum, void *p, int n);

// convert to intel byte order
ushort
xshort(ushort x)
{
  ushort y;
  uchar *a = (uchar*)&y;
  a[0] = x;
  a[1] = x >> 8;
  return y;
}

uint
xint(uint x)
{
  uint y;
  uchar *a = (uchar*)&y;
  a[0] = x;
  a[1] = x >> 8;
  a[2] = x >> 16;
  a[3] = x >> 24;
  return y;
}

/*
int
main(void)
*/
int mkfs(void)
{
  int i, cc, fd;
  uint rootino, inum, off;
  struct dirent de;
  __attribute__((__aligned__(4))) char buf[BSIZE];
  struct dinode din;

  static_assert(sizeof(int) == 4, "Integers must be 4 bytes!");

  assert((BSIZE % sizeof(struct dinode)) == 0);
  assert((BSIZE % sizeof(struct dirent)) == 0);

  nmeta = 2 + ninodeblocks + nbitmap;
  nblocks = SIZE - nlog - nmeta;

  sb.size = xint(SIZE);
  sb.nblocks = xint(nblocks); // so whole disk is size sectors
  sb.ninodes = xint(NINODES);
  sb.nlog = xint(nlog);
  printf("nmeta %d (boot, super, inode blocks %u, bitmap blocks %u) datablocks %d log %u total blocks # = %d\n", nmeta, ninodeblocks, nbitmap, nblocks, nlog, SIZE);
  printf("ninodes: %d\n", sb.ninodes);
  printf("sb: size of fs img = %d blocks; datablocks %d; inodes # %d; log blocks %d\n", sb.size, sb.nblocks, sb.ninodes, sb.nlog);

  freeblock = nmeta;     // the first free block that we can allocate
  
  for(i = 0; i < SIZE; i++) {
    wsect(i, zeroes);
  }

  memset(buf, 0, sizeof(buf));
  memmove(buf, &sb, sizeof(sb));
  wsect(1, buf);
  printf("[mkfs] wsect 1 buf[%ld]:  ", sizeof(sb));
  for(int i = 0; i < sizeof(sb); i++) {
    printf("%d,", buf[i]);
  }
  printf("\n");
  rsect(1, buf);
  for(int i = 0; i < sizeof(sb); i++) {
    printf("%d,", buf[i]);
  }
  printf("\n");

  printf("-----\n[mkfs] root inode allocate: \n");
  rootino = ialloc(T_DIR);
  assert(rootino == ROOTINO);

  bzero(&de, sizeof(de));
  de.inum = xshort(rootino);
  strcpy(de.name, ".");
  iappend(rootino, &de, sizeof(de));
  printf("[mkfs] root inode allocation done\n-----\n");

  bzero(&de, sizeof(de));
  de.inum = xshort(rootino);
  strcpy(de.name, "..");
  iappend(rootino, &de, sizeof(de));

  printf("\n-------\n\n[mkfs] write new file: \n----------\n");

  // fix size of root inode dir
  rinode(rootino, &din);
  off = xint(din.size);
  off = ((off/BSIZE) + 1) * BSIZE;
  din.size = xint(off);
  winode(rootino, &din);

  balloc(freeblock);   // allocate all blocks up to freeblock

  memset(buf, 0, sizeof(buf));
  disk_read(65, (uint32_t *)buf);
  printf(":");
  for(int i = 0; i < 70; i++) {
    printf("%d,", buf[i]);
  }
  printf("\n");
  //exit(0);
  return 0;
}

void
wsect(uint sec, void *buf)
{
  static int wwcnt = 0;
  printf("[mkfs] write %d\n", sec);
  disk_write(sec, buf);
  if(wwcnt && wwcnt % 1000 == 0) {
      disk_flush();
      wwcnt = 0;
  } else {
      wwcnt++;
  }
 
 
//  __attribute__((__aligned__(4))) char tmpbuf[BSIZE];
//  disk_read(sec, tmpbuf);
//  for(int i = 0; i < 5; i++) {
//      printf("(%d,%d),", tmpbuf[i], ((char*)buf)[i]);
//  }
}

void
winode(uint inum, struct dinode *ip)
{
  __attribute__((__aligned__(4))) char buf[BSIZE];
  uint bn;
  struct dinode *dip;

  bn = IBLOCK(inum);
  rsect(bn, buf);
  dip = ((struct dinode*)buf) + (inum % IPB);
  *dip = *ip;
  printf("[mkfs] winode rsect inum = %d block num (lsa) =  %d  (type %d, nlink %d size %d, %d)\n:", inum, bn,
  ip->type, ip->nlink, ip->size, ip->addrs[NDIRECT]);
  printf("    >> ");
  for(int i = 0; i < sizeof(struct dinode); i++) {
    printf("%d,", buf[i]);
  }
  printf("[mkfs] winode wsect: ");
  wsect(bn, buf);
  printf("[mkfs] done winode\n");
}

void
rinode(uint inum, struct dinode *ip)
{
  __attribute__((__aligned__(4))) char buf[BSIZE];
  uint bn;
  struct dinode *dip;

  bn = IBLOCK(inum);
  rsect(bn, buf);
  dip = ((struct dinode*)buf) + (inum % IPB);
  *ip = *dip;
}

void
rsect(uint sec, void *buf)
{
  printf("[mkfs] read %d\n", sec);
  disk_read(sec, buf);
}

static uint
ialloc(ushort type)
{
  uint inum = freeinode++;
  struct dinode din;

  bzero(&din, sizeof(din));
  din.type = xshort(type);
  din.nlink = xshort(1);
  din.size = xint(0);
  winode(inum, &din);
  printf("mkfs done ialloc\n");
  return inum;
}

void
balloc(int used)
{
  __attribute__((__aligned__(4))) uchar buf[BSIZE];
  int i;

  printf("balloc: first %d blocks have been allocated\n", used);
  assert(used < BSIZE*8);
  bzero(buf, BSIZE);
  for(i = 0; i < used; i++){
    buf[i/8] = buf[i/8] | (0x1 << (i%8));
  }
  for(int i = 0; i < used; i++) {
    printf("%d,", buf[i]);
  }
  printf("\n");
  printf("balloc: write bitmap block at sector %d\n", ninodeblocks+2);
  wsect(ninodeblocks+2, buf);
}

#define min(a, b) ((a) < (b) ? (a) : (b))

void
iappend(uint inum, void *xp, int n)
{
  char *p = (char*)xp;
  uint fbn, off, n1;
  struct dinode din;
  __attribute__((__aligned__(4))) char buf[BSIZE];
  uint indirect[NINDIRECT];
  uint x;

  rinode(inum, &din);
  printf("[mkfs] iappend inum %d\n", inum);
  off = xint(din.size);
  while(n > 0){
    fbn = off / BSIZE;
    assert(fbn < MAXFILE);
    if(fbn < NDIRECT){
      if(xint(din.addrs[fbn]) == 0){
        din.addrs[fbn] = xint(freeblock++);
      }
      x = xint(din.addrs[fbn]);
    } else {
      if(xint(din.addrs[NDIRECT]) == 0){
        printf("[mkfs]    >> allocate indirect block\n");
        din.addrs[NDIRECT] = xint(freeblock++);
      }
      printf("[mkfs]    >> %d %d\n", din.addrs[NDIRECT], xint(din.addrs[NDIRECT]));
      printf("[mkfs]    >> read indirect block\n");
      rsect(xint(din.addrs[NDIRECT]), (char*)indirect);
      if(indirect[fbn - NDIRECT] == 0){
        indirect[fbn - NDIRECT] = xint(freeblock++);
        wsect(xint(din.addrs[NDIRECT]), (char*)indirect);
      }
      x = xint(indirect[fbn-NDIRECT]);
    }
    n1 = min(n, (fbn + 1) * BSIZE - off);
    rsect(x, buf);
    bcopy(p, buf + off - (fbn * BSIZE), n1);
    wsect(x, buf);
    n -= n1;
    off += n1;
    p += n1;
  }
  printf("[mkfs] iappend inum %d size goes from %d ", inum, din.size);
  din.size = xint(off);
  printf("to size %d\n", din.size);
  winode(inum, &din);
}
