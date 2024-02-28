# See LICENSE for license details.

#*****************************************************************************
# rdtime.S
#-----------------------------------------------------------------------------
#
# Test rdtime instruction.
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
  rdtime   x1;
  rdtime   x2;
  rdtime   x3;
  rdtime   x4;

  addi      x5, x1, 5;
  bgeu      x5, x2, fail;

  addi      x5, x2, 5;
  bgeu      x5, x3, fail;

  addi      x5, x2, 5;
  bgeu      x5, x4, fail;

test_3:
  rdtimeh   x1;
  rdtimeh   x2;
  rdtimeh   x3;

  bne       x1, x0, fail;
  bne       x2, x0, fail;
  bne       x3, x0, fail;

#endif

  TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
