# See LICENSE for license details.

#*****************************************************************************
# csrrw.S
#-----------------------------------------------------------------------------
#
# Test csrw instruction.
#

#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV32U
RVTEST_CODE_BEGIN

  #-------------------------------------------------------------
  # Read/Write mtval
  #-------------------------------------------------------------

#if defined(INT_CSR) && (INT_CSR == 1)

  csrrw x0, 0x343, x0;

  TEST_CASE( 2, x3, 0x00000000, li  x1, 0x00000010; csrrw x3, 0x343, x1; );
  TEST_CASE( 3, x3, 0x00000010, li  x1, 0xFFFFFFFF; csrrw x3, 0x343, x1; );
  TEST_CASE( 4, x3, 0xFFFFFFFF, li  x1, 0x00000010; csrrw x3, 0x343, x1; );

#endif

  TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
