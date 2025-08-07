
PYTHON := python3
IVERILOG := iverilog$(ICARUS_SUFFIX)
VVP := vvp$(ICARUS_SUFFIX)

TEST_OBJS = $(addsuffix .o,$(basename $(wildcard tests/*.S)))
FIRMWARE_OBJS = firmware/start.o
GCC_WARNS = -Werror -Wall -Wextra -Wshadow -Wundef -Wpointer-arith -Wcast-qual -Wcast-align -Wwrite-strings
GCC_WARNS += -Wredundant-decls -Wstrict-prototypes -Wmissing-prototypes -pedantic
TOOLCHAIN_PREFIX = riscv32-unknown-elf-

SRC_DESIGN 	= $(wildcard ../rtl/*.v ../rtl/*.sv)
SRC_SIM 	= $(wildcard tb/*.v tb/*.sv)

CHUNKSIZE	?= 4
RFTYPE 		?= LOGIC
CONF 		?= MIN
MEMDLY1		?= 0
WITH_CSR 	?= 0

test: testbench.vvp firmware/firmware.hex
	$(VVP) -N $<

test_vcd: testbench.vvp firmware/firmware.hex
	$(VVP) -N $< +vcd +noerror

testbench.vvp: $(SRC_SIM) $(SRC_DESIGN)
	$(IVERILOG) -g2005-sv -DSIM -DDEBUG -DCHUNKSIZE=$(CHUNKSIZE) -DRFTYPE=\"$(RFTYPE)\" -DCONF=\"$(CONF)\" -DMEMDLY1=$(MEMDLY1) -o $@ $^
	chmod -x $@

firmware/firmware.hex: firmware/firmware.bin firmware/makehex.py
	$(PYTHON) firmware/makehex.py $< 32768 > $@

firmware/firmware.bin: firmware/firmware.elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary $< $@
	chmod -x $@

firmware/firmware.elf: $(FIRMWARE_OBJS) $(TEST_OBJS) firmware/sections.lds
	$(TOOLCHAIN_PREFIX)gcc -Os -mabi=ilp32 -march=rv32i -ffreestanding -nostdlib -o $@ \
		-Wl,--build-id=none,-Bstatic,-T,firmware/sections.lds,-Map,firmware/firmware.map,--strip-debug \
		$(FIRMWARE_OBJS) $(TEST_OBJS) -lgcc
	chmod -x $@
	$(TOOLCHAIN_PREFIX)objdump --disassemble-all $@ >> firmware/firmware.txt

firmware/start.o: firmware/start.S
	$(TOOLCHAIN_PREFIX)gcc -c -mabi=ilp32 -march=rv32i -o $@ $<

firmware/%.o: firmware/%.c
	$(TOOLCHAIN_PREFIX)gcc -c -mabi=ilp32 -march=rv32i_zicsr -Os --std=c99 $(GCC_WARNS) -ffreestanding -nostdlib -o $@ $<

tests/%.o: tests/%.S tests/riscv_test.h tests/test_macros.h
	$(TOOLCHAIN_PREFIX)gcc -c -DINT_CSR=$(WITH_CSR) -mabi=ilp32 -march=rv32i_zicsr -o $@ -DTEST_FUNC_NAME=$(notdir $(basename $<)) \
		-DTEST_FUNC_TXT='"$(notdir $(basename $<))"' -DTEST_FUNC_RET=$(notdir $(basename $<))_ret $<

clean:
	rm -vrf $(FIRMWARE_OBJS) $(TEST_OBJS) firmware/firmware.map firmware/start.o firmware/firmware.bin firmware/firmware.hex firmware/firmware.elf \
		testbench.vvp firmware/firmware.txt tb.vcd

.PHONY: test test_vcd
