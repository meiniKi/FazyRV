# See LICENSE for license details.

#*****************************************************************************
# rdinstret.S
#-----------------------------------------------------------------------------
#
# Test rdinstret instruction.
#

#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV32U
RVTEST_CODE_BEGIN

  #-------------------------------------------------------------
  # Read/Write mtval
  #-------------------------------------------------------------

#if INT_CSR==1

test_2:
  rdinstret   x1;
  rdinstret   x2;
  rdinstret   x3;
  rdinstret   x4;

  addi        x5, x1, 1;
  bne         x5, x2, fail;

  addi        x5, x2, 1;
  bne         x5, x3, fail;

  addi        x5, x3, 1;
  bne         x5, x4, fail;

test_3:
  rdinstreth  x1;
  rdinstreth  x2;
  rdinstreth  x3;

  bne         x1, x0, fail;
  bne         x2, x0, fail;
  bne         x3, x0, fail;

#endif

  TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
