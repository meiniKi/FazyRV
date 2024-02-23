
#define ENABLE_RVTST

.section .text
.global _start

_start:
    addi x1, zero, 0
    addi x2, zero, 0
    addi x3, zero, 0
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

#ifdef ENABLE_RVTST
#  define TEST(n) \
    .global n; \
    addi x1, zero, 1000; \
    jal zero,n; \
    .global n ## _ret; \
    n ## _ret:
#else
#  define TEST(n) \
    .global n ## _ret; \
    n ## _ret:
#endif

    TEST(lui)
    TEST(auipc)
    TEST(j)
    TEST(jal)
    TEST(jalr)

    TEST(csrrw)
    TEST(rdinstret)
    TEST(rdtime)
    TEST(ecall)

    TEST(beq)
    TEST(bne)
    TEST(blt)
    TEST(bge)
    TEST(bltu)
    TEST(bgeu)

    TEST(lb)
    TEST(lh)
    TEST(lw)
    TEST(lbu)
    TEST(lhu)

    TEST(sh)
    TEST(sb)
    TEST(sw)

    TEST(addi)
    TEST(slti) // also tests sltiu
    TEST(xori)
    TEST(ori)
    TEST(andi)
    TEST(slli)
    TEST(srli)
    TEST(srai)

    TEST(add)
    TEST(sub)
    TEST(sll)
    TEST(slt)
    TEST(xor)
    TEST(srl)
    TEST(sra)
    TEST(or)
    TEST(and)

    #TEST(mulh)
    #TEST(mulhsu)
    #TEST(mulhu)
    #TEST(mul)
    #TEST(div)
    #TEST(divu)
    #TEST(rem)
    #TEST(remu)
    #TEST(simple)

	/* print "DONE\n" */
	lui a0,0x10000000>>12
	addi a1,zero,'D'
	addi a2,zero,'O'
	addi a3,zero,'N'
	addi a4,zero,'E'
	addi a5,zero,'\n'
	sw a1,0(a0)
	sw a2,0(a0)
	sw a3,0(a0)
	sw a4,0(a0)
	sw a5,0(a0)

hlt:
    j hlt