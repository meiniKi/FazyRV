#ifndef _COMPLIANCE_MODEL_H
#define _COMPLIANCE_MODEL_H
#define RVMODEL_DATA_SECTION \
        .pushsection .tohost,"aw",@progbits;                            \
        .align 8; .global tohost; tohost: .dword 0;                     \
        .align 8; .global fromhost; fromhost: .dword 0;                 \
        .popsection;                                                    \
        .align 8; .global begin_regstate; begin_regstate:               \
        .word 128;                                                      \
        .align 8; .global end_regstate; end_regstate:                   \
        .word 4;

//RV_COMPLIANCE_HALT, adapted from SERV
#define RVMODEL_HALT                                              \
  la a0, begin_signature;	 \
  la a1, end_signature; \
  li a2, 0x80000000; \
  complience_halt_loop: \
      beq a0, a1, complience_halt_break; \
      addi a3, a0, 4; \
  complience_halt_loop2: \
      addi a3, a3, -1; \
  \
      lb a4, 0 (a3); \
      srai a5, a4, 4; \
      andi a5, a5, 0xF; \
      li a6, 10; \
      blt a5, a6, notLetter; \
      addi a5, a5, 39; \
  notLetter: \
      addi a5, a5, 0x30; \
      sw a5, 0 (a2); \
  \
      srai a5, a4, 0; \
      andi a5, a5, 0xF; \
      li a6, 10; \
      blt a5, a6, notLetter2; \
      addi a5, a5, 39; \
  notLetter2: \
      addi a5, a5, 0x30; \
      sw a5, 0 (a2); \
      bne a0, a3,complience_halt_loop2;  \
      addi a0, a0, 4; \
  \
      li a4, '\n'; \
      sw a4, 0 (a2); \
      j complience_halt_loop; \
      j complience_halt_break;		\
  complience_halt_break:; \
      lui	a0,0x90000000>>12;	\
      sw	a3,0(a0);

//  li x1, 1;                                                                   \
//  write_tohost:                                                               \
//    sw x1, tohost, t5;                                                        \
//    j write_tohost;

#define RVMODEL_BOOT

//RV_COMPLIANCE_DATA_BEGIN
#define RVMODEL_DATA_BEGIN                                              \
  RVMODEL_DATA_SECTION                                                        \
  .align 4;\
  .global begin_signature; begin_signature:

//RV_COMPLIANCE_DATA_END
#define RVMODEL_DATA_END                                                      \
  .align 4;\
  .global end_signature; end_signature:  

//RVTEST_IO_INIT
#define RVMODEL_IO_INIT
//RVTEST_IO_WRITE_STR
#define RVMODEL_IO_WRITE_STR(_R, _STR)
//RVTEST_IO_CHECK
#define RVMODEL_IO_CHECK()
//RVTEST_IO_ASSERT_GPR_EQ
#define RVMODEL_IO_ASSERT_GPR_EQ(_S, _R, _I)
//RVTEST_IO_ASSERT_SFPR_EQ
#define RVMODEL_IO_ASSERT_SFPR_EQ(_F, _R, _I)
//RVTEST_IO_ASSERT_DFPR_EQ
#define RVMODEL_IO_ASSERT_DFPR_EQ(_D, _R, _I)

#define RVMODEL_SET_MSW_INT       \
 li t1, 1;                         \
 li t2, 0x2000000;                 \
 sw t1, 0(t2);

#define RVMODEL_CLEAR_MSW_INT     \
 li t2, 0x2000000;                 \
 sw x0, 0(t2);

#define RVMODEL_CLEAR_MTIMER_INT

#define RVMODEL_CLEAR_MEXT_INT


#endif // _COMPLIANCE_MODEL_H
