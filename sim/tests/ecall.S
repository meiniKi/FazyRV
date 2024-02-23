# See LICENSE for license details.

#*****************************************************************************
# ecall.S
#-----------------------------------------------------------------------------
#
# Test ecall instruction.
#

#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV32U
RVTEST_CODE_BEGIN

#if INT_CSR==1

.global stvec_handler
.global cont_ecall

  j     cont_ecall
  
stvec_handler:
  nop
  nop
  nop
  nop
  mret

cont_ecall:
  # set mtval
  la    x1, stvec_handler;
  csrrw x0, 0x343, x1;

  # set mtie
  li    x1, 0x80;
  csrrw x0, 0x304, x1;

  # set mie
  li    x1, 0x8;
  csrrw x0, 0x300, x1;

  # execute ecall
  ecall;

#endif

  TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
