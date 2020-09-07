/**
 * FSCQ: a verified file system
 * 
 * Copyright (c) 2015, Massachusetts Institute of Technology
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include <stdio.h>
#include <errno.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/time.h>

/* Measure creating a large file and overwriting that file */

#define WSIZE (4096)
#define NAMESIZE 100
unsigned int FILESIZE = (4 * 1024 * 1024);

static char name[NAMESIZE];
static char buf[WSIZE];
static char *prog;
static char *dir;

void printstats(int reset)
{
  int fd;
  int r;

  sprintf(name, "%s/stats", dir);
  if((fd = open(name, O_RDONLY)) < 0) {
    printf("open %s fail\n", name);
    return;
  }

  bzero(buf, WSIZE);

  if ((r = read(fd, buf, WSIZE)) < 0) {
    perror("read");
    exit(1);
  }

  if (!reset) fprintf(stdout, "=== FS Stats ===\n%s========\n", buf);

  if ((r = close(fd)) < 0) {
    perror("close");
  }
}

int makefile()
{
  int i;
  int r;
  int fd;

  int n = FILESIZE/WSIZE;
  
  sprintf(name, "%s/d/f", dir);
  if((fd = open(name, O_RDWR | O_CREAT | O_TRUNC, S_IRWXU)) < 0) {
    printf("%s: create %s failed %s\n", prog, name, strerror(errno));
    exit(1);
  }

  sprintf(buf, "%s/stats", dir);
    
  for (i = 0; i < n; i++) {
    if (write(fd, buf, WSIZE) != WSIZE) {
      printf("%s: write %s failed %s\n", prog, name, strerror(errno));
      exit(1);
    }
  }
  if (fsync(fd) < 0) {
    printf("%s: fsync %s failed %s\n", prog, name, strerror(errno));
    exit(1);
  }

  lseek(fd, SEEK_SET, 0);
  write(fd, buf, WSIZE);
  close(fd);
  
  fd = open(".", O_DIRECTORY | O_RDONLY);
  if (fd < 0) {
    perror("open dir");
    exit(-1);
  }
  if (fsync(fd) < 0) {
    perror("fsync");
    exit(-1);
  }
}

int writefile()
{
  int i;
  int r;
  int fd;

  int n = FILESIZE/WSIZE;
  
  sprintf(name, "%s/d/f", dir);
  if((fd = open(name, O_RDWR, S_IRWXU)) < 0) {
    printf("%s: open %s failed %s\n", prog, name, strerror(errno));
    exit(1);
  }
  
  sprintf(buf, "%s/stats", dir);
  
  for (int g = 0; g < 10; g++) {
    for (i = 0; i < n; i++) {
      if (write(fd, buf, WSIZE) != WSIZE) {
        printf("%s: write %s failed %s\n", prog, name, strerror(errno));
        exit(1);
      }
      if (((i + 1) * WSIZE) % (1 * 1024 * 1024) == 0) {
        if (fsync(fd) < 0) {
          printf("%s: fsync %s failed %s\n", prog, name, strerror(errno));
          exit(1);
        }
      }
    }
    lseek(fd, 0, SEEK_SET);
  }
  if ((i * WSIZE) % (10 * 1024 * 1024) != 0 && fsync(fd) < 0) {
    printf("%s: fsync %s failed %s\n", prog, name, strerror(errno));
    exit(1);
  }
  close(fd);
}

int main(int argc, char *argv[])
{
  long time;
  struct timeval before;
  struct timeval after;
  float tput;

  if (argc < 2) {
    printf("Usage: %s basedir\n", argv[0]);
    exit(-1);
  }
  if (argc == 3) {
    FILESIZE = atoi(argv[2]) * 1024 * 1024;
    printf("file size = %d MB\n", atoi(argv[2]));
  }

  
  prog = argv[0];
  dir = argv[1];
  sprintf(name, "%s/d", dir);
  if (mkdir(name,  S_IRWXU) < 0) {
    printf("%s: create %s failed %s\n", prog, name, strerror(errno));
    exit(1);
  }

  //printstats(1);
    
  gettimeofday ( &before, NULL );  
  makefile();
  gettimeofday ( &after, NULL );

  time = (after.tv_sec - before.tv_sec) * 1000000 +
  (after.tv_usec - before.tv_usec);
  tput = ((float) (FILESIZE/1024) /  (time / 1000000.0));
  //printf("makefile %d MB %ld usec throughput %5.1f KB/s\n", FILESIZE/(1024*1024), time, tput);

  //printstats(0);
    
  gettimeofday ( &before, NULL );  
  writefile();
  gettimeofday ( &after, NULL );
  
  time = (after.tv_sec - before.tv_sec) * 1000000 +
  (after.tv_usec - before.tv_usec);
  tput = ((float) (FILESIZE/1024) /  (time / 1000000.0)) * 10;
  printf("writefile %d MB 10 times %ld usec throughput %5.1f KB/s\n", FILESIZE/(1024*1024), time, tput);

  //printstats(0);

}
