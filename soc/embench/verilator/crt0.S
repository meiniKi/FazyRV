
.section .text
.global _start

_start:
.option push
.option norelax
  la gp, __global_pointer$
.option pop

	addi x1, zero, 0
    lui sp,(128*1024)>>12

	addi x4, zero, 0
	addi x5, zero, 0
	addi x6, zero, 0
	addi x7, zero, 0
	addi x8, zero, 0
	addi x9, zero, 0
	addi x10, zero, 0
	addi x11, zero, 0
	addi x12, zero, 0
	addi x13, zero, 0
	addi x14, zero, 0
	addi x15, zero, 0
	addi x16, zero, 0
	addi x17, zero, 0
	addi x18, zero, 0
	addi x19, zero, 0
	addi x20, zero, 0
	addi x21, zero, 0
	addi x22, zero, 0
	addi x23, zero, 0
	addi x24, zero, 0
	addi x25, zero, 0
	addi x26, zero, 0
	addi x27, zero, 0
	addi x28, zero, 0
	addi x29, zero, 0
	addi x30, zero, 0
	addi x31, zero, 0
    jal main

    beqz a0, is_success
    li a3, 4
    j write

is_success:
    li a3, 2

write:
	li a1, 0x10000000
	sw a3, 0(a1)

done:
	j write