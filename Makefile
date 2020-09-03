CFLAGS_FUSE = `pkg-config fuse --cflags --libs`
CFLAGS = \
	-DFUSEFS \
	-MD \
	-fopenmp \
	-llightnvm \
	-laio \
	-I./src \
	$(CFLAGS_FUSE) \

VPATH=./src
SRC_XV6_BASE = $(addprefix xv6/, \
	fuse.c \
	spinlock.c \
	bio.c \
	ide.c \
	fs.c \
	file.c \
	pipe.c \
	sysfile.c \
	mkfs.c)

TARGETS_XV6 = xv6fs-xlog-gcm xv6fs-xlog xv6fs-xflush xv6fs
TARGETS = \
	ftl.o \
	mkftl-vblk \
	fillone-vblk \
	randwr-scftl \
	randwr-async \
	randwr-sync \
	randwr-pblk \
	$(TARGETS_XV6) \

all: $(TARGETS)

ftl.o: src/verif/ftl.ll
	clang -g $< -c -fPIC -o $@

mkftl-emu: mkftl.c ftl.o flashemu.c
	gcc -g $^ -o $@

test-emu: test.c disk.c ftl.o flashemu.c
	gcc -g $^ -o $@

randwr-emu: randwr.c disk.c ftl.o flashemu.c
	gcc -g $^ -o $@

crash-test: crash-test.c disk.c ftl.o flashemu.c
	gcc -g $^ -o $@ -lpthread

mkftl-lightnvm: mkftl.c ftl.o lightnvm.c
	gcc -g $^ $(CFLAGS) -o $@

fillone-lightnvm: fillone.c ftl.o lightnvm.c
	gcc -g $^ $(CFLAGS) -o $@

test-lightnvm: test.c disk.c ftl.o lightnvm.c
	gcc -g $^ $(CFLAGS) -o $@

vblk: vblk-test.c vblk.c
	gcc -g $^ $(CFLAGS) -o $@

mkftl-vblk: mkftl.c disk.c ftl.o vblk.c
	gcc -g $^ $(CFLAGS) -o $@

fillone-vblk: fillone.c ftl.o vblk.c
	gcc -g $^ $(CFLAGS) -o $@

test-vblk: test.c disk.c ftl.o vblk.c
	gcc -g $^ $(CFLAGS) -o $@

randwr-scftl: randwr.c disk.c ftl.o vblk.c
	gcc -g $^ $(CFLAGS) -o $@

randwr-async: randwr.c disk.c ftl-async.c vblk.c
	gcc -g $^ $(CFLAGS) -o $@

randwr-sync: randwr.c disk.c ftl-sync.c vblk.c
	gcc -g $^ $(CFLAGS) -o $@

randwr-pblk: randwr.c disk-pblk.c
	gcc -g $^ $(CFLAGS) -o $@

seqwr-scftl: seqwr.c disk.c ftl.o vblk.c
	gcc -g $^ $(CFLAGS) -o $@

seqwr-async: seqwr.c disk.c ftl-async.c vblk.c
	gcc -g $^ $(CFLAGS) -o $@

seqwr-sync: seqwr.c disk.c ftl-sync.c vblk.c
	gcc -g $^ $(CFLAGS) -o $@

seqwr-pblk: seqwr.c disk-pblk.c
	gcc -g $^ $(CFLAGS) -o $@

chkpt-profile: chkpt-profile.c ftl.o vblk.c
	gcc -g $^ $(CFLAGS) -o $@

xv6fs-xlog-gcm: $(SRC_XV6_BASE) xv6/sclog-gcm.c disk.c ftl.o vblk.c
	gcc -g $^ $(CFLAGS) -o $@

xv6fs-xlog: $(SRC_XV6_BASE) xv6/sclog.c disk.c ftl.o vblk.c
	gcc -g $^ $(CFLAGS) -o $@

xv6fs-xflush: $(SRC_XV6_BASE) xv6/synclog.c disk.c ftl-sync.c vblk.c
	gcc -g $^ $(CFLAGS) -o $@

xv6fs: $(SRC_XV6_BASE) xv6/asynclog.c disk.c ftl-async.c vblk.c
	gcc -g $^ $(CFLAGS) -o $@

clean:
	rm -rf $(TARGETS) *.d
.PHONY: clean
