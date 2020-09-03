#pragma once

#include "mnode.hh"

extern u64 root_inum;
extern mfs* root_fs;
extern mfs* anon_fs;
sref<mnode> namei(sref<mnode> cwd, const char* path);
sref<mnode> nameiparent(sref<mnode> cwd, const char* path, strbuf<DIRSIZ>* buf);
s64 readi(sref<mnode> m, char* buf, u64 start, u64 nbytes);
s64 writei(sref<mnode> m, const char* buf, u64 start, u64 nbytes,
           mfile::resizer* resize = nullptr);

class print_stream;
void mfsprint(print_stream *s);
