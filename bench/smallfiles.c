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
#include <stdint.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/time.h>

#define N 1000
#define FILESIZE 100
#define NAMESIZE 100

static char name[NAMESIZE];
static char buf[FILESIZE]; 
static char *dir;

void printstats(int reset)
{
  int fd;
  int r;

  sprintf(name, "/tmp/xv6fs/stats");
  if((fd = open(name, O_RDONLY)) < 0) {
    return;
  }

  bzero(buf, FILESIZE);

  if ((r = read(fd, buf, FILESIZE)) < 0) {
    perror("read");
    exit(1);
  }

  if (!reset)
    printf("=== FS Stats ===\n%s========\n", buf);

  if ((r = close(fd)) < 0) {
    perror("close");
  }
}

static uint64_t
usec_now()
{
  struct timeval tv;

  gettimeofday(&tv, NULL);

  uint64_t res = tv.tv_sec;
  res *= 1000000;
  res += tv.tv_usec;
  return res;
}

int main(int argc, char *argv[])
{
  int i;
  int r;
  int fd;
  uint64_t start, end;

  if (argc != 3) {
    printf("Usage: %s basedir sec\n", argv[0]);
    exit(-1);
  }
  int tts = 1000000;
  int total_sec = atoi(argv[2]);
  printf("sec: %d\n", total_sec);
  tts *= total_sec;
  
  dir = argv[1];
  sprintf(buf, "%s/d", argv[1]);
  if (mkdir(buf,  S_IRWXU) < 0) {
    printf("%s: create %s failed %s\n", argv[0], buf, strerror(errno));
    exit(1);
  }
  printstats(1);
  start = usec_now();
  for (i = 0; ; i++) {
    sprintf(name, "%s/d/f%d", argv[1], i);
    if((fd = open(name, O_RDWR | O_CREAT | O_TRUNC, S_IRWXU)) < 0) {
      printf("%s: create %s failed %s\n", argv[0], name, strerror(errno));
      exit(1);
    }
    if (write(fd, buf, FILESIZE) != FILESIZE) {
      printf("%s: write %s failed %s\n", argv[0], name, strerror(errno));
      exit(1);
    }
    if (fsync(fd) < 0) {
      printf("%s: fsync %s failed %s\n", argv[0], name, strerror(errno));
      exit(1);
    }
    close(fd);

    end = usec_now();
    if (end - start > tts)
      break;
  }

  printf("%d files per %ld usec\n", i, end-start);

  printstats(0);
}
