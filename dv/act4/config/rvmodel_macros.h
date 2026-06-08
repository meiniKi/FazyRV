// Modified from https://github.com/riscv/riscv-arch-test/blob/act4/config/cores/cvw/cvw-rv64gc/rvmodel_macros.h

#ifndef _COMPLIANCE_MODEL_H
#define _COMPLIANCE_MODEL_H

#define RVMODEL_DATA_SECTION

#define RVMODEL_BOOT

#define RVMODEL_HALT_PASS  \
  li x1, 1                ;\
  li t0, 0x8c000000           ;\
  write_tohost_pass:      ;\
    sw x1, 0(t0)          ;\
  self_loop_pass:         ;\
    j self_loop_pass      ;\

#define RVMODEL_HALT_FAIL \
  li x1, 3                ;\
  li t0, 0x8c000000           ;\
  write_tohost_fail:      ;\
    sw x1, 0(t0)          ;\
  self_loop_fail:         ;\
    j self_loop_fail      ;\



#define RVMODEL_IO_INIT(_R1, _R2, _R3)

// # Prints a null-terminated string using a DUT specific mechanism.
// # A pointer to the string is passed in _STR_PTR.
// # _R1, _R2, and _R3 can be used as temporary registers if needed.
// # Do not modify any other registers (or make sure to restore them).
#define RVMODEL_IO_WRITE_STR(_R1, _R2, _R3, _STR_PTR)               \
1:                           ;                       \
  lbu _R1, 0(_STR_PTR)        ;/* Load byte */        \
  beqz _R1, 2f                ;/* Exit if null */     \
  li _R2, 0x8a000000          ;/* load print address */ \
  sb _R1, 0(_R2)              ;/* store byte, testbench will print it */ \
  addi _STR_PTR, _STR_PTR, 1 ;/* Next char */        \
  j 1b                       ;/* Loop */             \
2:

#define RVMODEL_ACCESS_FAULT_ADDRESS 0x00000000

#define RVMODEL_INTERRUPT_LATENCY 10

#define RVMODEL_TIMER_INT_SOON_DELAY 100

#define RVMODEL_MTIME_ADDRESS  0x0200BFF8  /* Address of mtime CSR */

#define RVMODEL_MTIMECMP_ADDRESS 0x02004000 /* Address of mtimecmp CSR */

// Machine Interrupts

#define CLINT_BASE_ADDRESS 0x02000000
#define MSIP_ADDRESS (CLINT_BASE_ADDRESS + 0x0)

#define RVMODEL_SET_MEXT_INT(_R1, _R2)

#define RVMODEL_CLR_MEXT_INT(_R1, _R2)

#define RVMODEL_SET_MSW_INT(_R1, _R2)

#define RVMODEL_CLR_MSW_INT(_R1, _R2)

#define CVW_SSIP_ADDRESS (CLINT_BASE_ADDRESS + 0xC000)

#define RVMODEL_SET_SEXT_INT(_R1, _R2)

#define RVMODEL_CLR_SEXT_INT(_R1, _R2)

#define RVMODEL_SET_SSW_INT(_R1, _R2)

#define RVMODEL_CLR_SSW_INT(_R1, _R2)

#endif // _COMPLIANCE_MODEL_H