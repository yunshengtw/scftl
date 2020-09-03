#include "types.h"
#include "stat.h"
#include "user.h"
#include "fs.h"
#include "wq.hh"

const char*
fmtname(const char *path)
{
  static char buf[DIRSIZ+1];
  const char *p;
  
  // Find first character after last slash.
  for(p=path+strlen(path); p >= path && *p != '/'; p--)
    ;
  p++;
  
  // Return blank-padded name.
  if(strlen(p) >= DIRSIZ)
    return p;
  memmove(buf, p, strlen(p));
  memset(buf+strlen(p), ' ', DIRSIZ-strlen(p));
  return buf;
}

void
ls(const char *path)
{
  char buf[512], *p;
  int fd;
  struct dirent de;
  struct stat st;
  
  if((fd = open(path, 0)) < 0){
    fprintf(2, "ls: cannot open %s\n", path);
    return;
  }
  
  if(fstat(fd, &st) < 0){
    fprintf(2, "ls: cannot stat %s\n", path);
    close(fd);
    return;
  }
  
  switch(st.type){
  case T_FILE:
    fprintf(1, "%s %d %d %d\n", fmtname(path), st.type, st.ino, st.size);
    break;
  
  case T_DIR:
    if(strlen(path) + 1 + DIRSIZ + 1 > sizeof buf){
      fprintf(1, "ls: path too long\n");
      break;
    }
    strcpy(buf, path);
    p = buf+strlen(buf);
    *p++ = '/';
    while(read(fd, &de, sizeof(de)) == sizeof(de)){
      if(de.inum == 0)
        continue;
      memmove(p, de.name, DIRSIZ);
      p[DIRSIZ] = 0;
      if(stat(buf, &st) < 0){
        fprintf(1, "ls: cannot stat %s\n", buf);
        continue;
      }
      fprintf(1, "%s %d %d %d\n", fmtname(buf), st.type, st.ino, st.size);
    }
    break;
  }
  close(fd);
}

void
work(void *arg)
{
  u64 tid = (u64)arg;
  // grab and push work  (may divide into blocks? and call ls on a block)?
  // maybe implement getdirent sys call that gives you some unread dir entry
  printf("%d\n", tid);
  while (wq_trywork()) ;
}

int
main(int argc, char *argv[])
{
  int i;
  int nthread = 4;

  wq_init(nthread);   // create a workqueue instance with nthread workers

  // create some intial work
  if(argc < 2){
    // ls(".");
    struct work *w = (struct work *) malloc(sizeof(struct work));
    w->rip = (void*) ls;
    w->arg0 = (void *) ".";
    wq_push(w);
  } else {
    for(i=1; i<argc; i++) {
      // ls(argv[i]);
      struct work *w = (struct work *) malloc(sizeof(struct work));
      w->rip = (void*) ls;
      w->arg0 = (void *) argv[i];
      wq_push(w);
    }
  }

  // start workers; terminate when all workers have no work
  wq_start();

  return 0;
}
