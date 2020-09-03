# This Makefile is copied from uw-unsat/serval
SERVAL_DIR              := ..
OLEVEL				    := 2
ARCH                    := riscv64
O                       := ./generated
S			:= ../src
CONFIG_DRAM_START       := 0x80000000

NPROC                   = $(shell nproc 2> /dev/null)
ifeq ($(NPROC),)
NPROC                   = 4
endif

RACO_JOBS               := $(NPROC)
RACO_TIMEOUT            := 120000
RACO_TEST               := raco test --table --timeout $(RACO_TIMEOUT) --jobs $(RACO_JOBS)

# no built-in rules and variables
MAKEFLAGS       += --no-builtin-rules --no-builtin-variables

BASE_CFLAGS     += -ffreestanding
BASE_CFLAGS     += -fno-stack-protector
BASE_CFLAGS     += -fno-strict-aliasing
# make it simpler for symbolic execution to track PC
BASE_CFLAGS     += -fno-jump-tables
# no unaligned memory accesses
BASE_CFLAGS     += -mstrict-align
BASE_CFLAGS     += -g -O$(OLEVEL)
BASE_CFLAGS     += -Wall -Wno-attributes -MD -MP

CONFIG_CFLAGS   += -DCONFIG_DRAM_START=$(CONFIG_DRAM_START)

CFLAGS          += $(BASE_CFLAGS) $(CONFIG_CFLAGS)
CFLAGS          += -mcmodel=medany
# no floating point
CFLAGS          += -mabi=lp64
CFLAGS          += -ffunction-sections -fdata-sections
CFLAGS          += -fno-PIE
CFLAGS          += -march=rv64ima

LDFLAGS         += -nostdlib
LDFLAGS         += --gc-sections

UBSAN_CFLAGS    += -fsanitize=integer-divide-by-zero
UBSAN_CFLAGS    += -fsanitize=shift
UBSAN_CFLAGS    += -fsanitize=signed-integer-overflow

include ./Makefile.lib

SERVAL_LLVM             := racket ./serval-llvm.rkt

verif: ftl.rkt 
	$(Q)cp $(O)/ftl.ll $(S)/verif/ftl.ll
	$(RACO_TEST) $^

ftl.rkt: $(O)/ftl.ll.rkt $(O)/ftl.asm.rkt $(O)/ftl.map.rkt $(O)/ftl.globals.rkt

$(O)/ftl.ll.rkt: $(O)/ftl.ll
	$(QUIET_GEN)$(SERVAL_LLVM) < $< > $@~
	$(Q)sed -i'.bk' -e 's/serval\/llvm/"..\/lib\/llvm-extend.rkt"/g' $@~
	$(Q)rm $@~.bk
	$(Q)mv $@~ $@

$(O)/ftl.globals.rkt: $(O)/ftl.elf
	$(Q)echo "#lang reader serval/lang/dwarf" > $@~
	$(QUIET_GEN)$(OBJDUMP) --dwarf=info $< >> $@~
	$(Q)mv $@~ $@

# --prefix-addresses prints the complete address on each line
$(O)/ftl.asm: $(O)/ftl.elf
	$(QUIET_GEN)$(OBJDUMP) -M no-aliases --prefix-addresses -w -f -d -z --show-raw-insn "$<" > "$@"

# sort addresses for *.map.rkt
$(O)/ftl.map: $(O)/ftl.elf
	$(QUIET_GEN)$(NM) --print-size --numeric-sort "$<" > "$@"

$(O)/%.o: $(S)/%.c
	$(Q)$(MKDIR_P) $(@D)
	$(QUIET_CC)$(CC) -o $@ -c $(CFLAGS) -D__MODULE__='"$(basename $(notdir $<))"' $<

$(O)/ftl.asm.rkt: $(O)/ftl.asm
	$(QUIET_GEN)echo "#lang reader serval/riscv/objdump" > $@~ && \
		cat $< >> $@~
	$(Q)mv $@~ $@

$(O)/ftl.map.rkt: $(O)/ftl.map
	$(QUIET_GEN)echo "#lang reader serval/lang/nm" > $@~ && \
		cat $< >> $@~
	$(Q)mv "$@~" "$@"

$(O)/ftl.elf: $(O)/ftl.o $(O)/flash.o
	$(QUIET_LD)$(LD) -o $@ -e $(CONFIG_DRAM_START) -Ttext $(CONFIG_DRAM_START) $(filter-out --gc-sections,$(LDFLAGS)) $^

$(O)/ftl.ll: $(S)/ftl.c
	$(Q)$(MKDIR_P) $(@D)
	$(QUIET_CC)$(LLVM_CC) -o $@ -mno-sse -S -emit-llvm -fno-discard-value-names $(UBSAN_CFLAGS) -Wno-unused-command-line-argument -I include $(filter-out -g,$(BASE_CFLAGS)) $(CONFIG_CFLAGS) -DCONFIG_VERIFICATION_LLVM -c $<

clean:
	rm -rfv "$(O)"

.PHONY: verif
