CFLAGS = -I./src

VPATH=../src

TARGETS = \
	ftl.o \
	mkftl-emu \
	crash-test

all: $(TARGETS)

ftl.o: verif/ftl.ll
	clang -g $< -c -fPIC -o $@

mkftl-emu: mkftl.c ftl.o flashemu.c
	gcc -g $^ -o $@

crash-test: crash-test.c disk.c ftl.o flashemu.c
	gcc -g $^ -o $@ -lpthread

clean:
	rm -rf $(TARGETS) *.d
.PHONY: clean
