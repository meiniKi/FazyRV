// Copyright (c) 2023 - 2024 Meinhard Kissich
// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
// File  :  fazyrv_core.sv
// Usage :  FazyRV core.
// Param
//  - CHUNKSIZE         Data path width (1, 2, 4, or 8)
//  - CONF              Configuration of the processor (MIN, INT, or CSR).
//  - MTVAL             Initial value of the mtval CSR (if present).
//  - BOOTADR           Boot address of the core, i.e., first address fetched.
//  - RFTYPE            RAM type used for register file. Required in the control
//                      logic to adapt for delays.
//  - MEMDLY1           TODO
//
// Ports
//  - clk_i             Clock input, sensitive to rising edge.
//  - rst_in            Reset, low active.
//  - tirq_i            Timer interrupt input if present (depending of CONF).
//
//  - trap_o            Executing trap.
//
//  - wb_imem_stb_o     Instruction memory Wishbone interface.
//  - wb_imem_cyc_o
//  - wb_imem_adr_o
//  - wb_imem_dat_i
//  - wb_imem_ack_i
//
//  - wb_dmem_cyc_o     Data memory Wishbone interface.
//  - wb_dmem_stb_o
//  - wb_dmem_we_o
//  - wb_dmem_ack_i
//  - wb_dmem_be_o
//  - wb_dmem_dat_i
//  - wb_dmem_adr_o
//  - wb_dmem_dat_o
//                    Register file interface.
//  - rf_shft_o         Shift regfile register to next chunk.
//  - rf_ram_wstb_o     Strobe to write data to the regfile.
//  - rf_ram_rstb_o     Strobe to read either ra or rb.
//  - rf_rs1_o          Register address of ra.
//  - rf_rs2_o          Register address of rb.
//  - rf_rd_o           Register address to write.
//  - rf_we_o           Write enable.
//  - rf_ra_i           Register ra chunk data.
//  - rf_rb_i           Register rb chunk data.
//  - rf_res_o          Chunk data to write.
//
//  - rf_hpmtc_o        RW in address space of HPM and 64-bit timer counter.
//  - rf_csr_o          Inform regfile to use CSR address space.
//  - rf_csr_6_o        Bit 6 of instruction field.
//  - rf_trap_o         Entering trap.
//  - rf_mret_o         Returning from trap.
//  - rf_mcause30_o     Bit 3 and bit 0 from mcause.
//  - rf_mcause_int_o   Trap is interrupt.
//  - rf_mtie_i         Interrupt enable.
//
//  - RVFI_OUTPUTS      RVFI used for formal checks.
// -----------------------------------------------------------------------------

module fazyrv_core #(
  parameter CHUNKSIZE = 2,
  parameter CONF      = "MIN",
  parameter MTVAL     = 0,
  parameter BOOTADR   = 0,
  parameter RFTYPE    = "BRAM_DP_BP",
  parameter MEMDLY1   = 0
) (
  input  logic          clk_i,
  input  logic          rst_in,
  input  logic          tirq_i,

  output logic          trap_o,

  output logic          wb_imem_stb_o,
  output logic          wb_imem_cyc_o,
  output logic [31:0]   wb_imem_adr_o,
  input  logic [31:0]   wb_imem_dat_i,
  input  logic          wb_imem_ack_i,

  output logic          wb_dmem_cyc_o,
  output logic          wb_dmem_stb_o,
  output logic          wb_dmem_we_o,
  input  logic          wb_dmem_ack_i,
  output logic [3:0]    wb_dmem_be_o,
  input  logic [31:0]   wb_dmem_dat_i,
  output logic [31:0]   wb_dmem_adr_o,
  output logic [31:0]   wb_dmem_dat_o,

  output logic                  rf_shft_o,
  output logic                  rf_ram_wstb_o,
  output logic                  rf_ram_rstb_o,
  output logic [4:0]            rf_rs1_o,
  output logic [4:0]            rf_rs2_o,
  output logic [4:0]            rf_rd_o,
  output logic                  rf_we_o,
  input  logic [CHUNKSIZE-1:0]  rf_ra_i,
  input  logic [CHUNKSIZE-1:0]  rf_rb_i,
  output logic [CHUNKSIZE-1:0]  rf_res_o,

  output logic                  rf_hpmtc_o,
  output logic                  rf_csr_o,
  output logic                  rf_csr_6_o,
  output logic                  rf_trap_o,
  output logic                  rf_mret_o,
  output logic [1:0]            rf_mcause30_o,
  output logic                  rf_mcause_int_o,
  input  logic                  rf_mtie_i
`ifdef RISCV_FORMAL
  , `RVFI_OUTPUTS
`endif
);

localparam REG_WIDTH = 32;

logic imem_stb;

logic [4:0]           id_rs1;
logic [4:0]           id_rs2;
logic [4:0]           id_rd;
logic [CHUNKSIZE-1:0] id_imm;

logic id_alu_arith;
logic id_alu_en_a;
logic id_alu_sub;
logic id_alu_xor;
logic id_alu_and;
logic id_alu_cmp_sig;
logic id_alu_cmp_eq;

logic id_aux_use_cmp;
logic id_instr_any_br;
logic id_instr_ld;
logic id_ls_b;
logic id_ls_h;
logic id_ls_w;

logic id_instr_st;
logic id_instr_jmp;
logic id_instr_slt;
logic id_instr_shft;
logic id_instr_left;
logic id_instr_csr;
logic id_csr_hpmtc;
logic id_csr_6;
logic id_csr_high;
logic id_mret;

logic [1:0] id_mcause30;

logic id_except;

logic cntrl_lsb;
logic cntrl_msb;
logic [$clog2(REG_WIDTH/CHUNKSIZE)-1:0] cntrl_icyc;

logic hlt_spm_a;
logic hlt_regs;
logic hlt_imm;

logic shft_done;

logic id_aux_rs_a_pc;
logic id_aux_rs_b_imm;
logic id_aux_b_spm_d;
logic id_alu_cmp_inv;
logic id_alu_aux_rev;

logic id_spm_d_sext;
logic id_rf_we;

logic [3:0] id_ls_mask;
logic       id_ld_sext;

logic cntrl_cyc_ack;
logic cntrl_cyc_two;
logic cntrl_cyc_shft;
logic cntrl_cyc_two_shift_next;

logic [CHUNKSIZE-1:0] ex_ra_mxd;
logic [CHUNKSIZE-1:0] ex_rb_mxd;

logic [CHUNKSIZE-1:0] ex_ra;
logic [CHUNKSIZE-1:0] ex_rb;
logic [CHUNKSIZE-1:0] ex_res;
logic                 ex_cmp_tmp;
logic                 ex_cmp;

logic [CHUNKSIZE-1:0] spm_d_dout;
logic [CHUNKSIZE-1:0] spm_d_pc_out;
logic                 spm_d_ld_par;

logic [31:0]          spm_a_par;
logic [CHUNKSIZE-1:0] spm_a_ser;

logic dmem_stb;

// traps
logic exc_misalngd;

logic br_and_taken;

logic [CHUNKSIZE-1:0] rf_ra;
logic [CHUNKSIZE-1:0] rf_rb;
logic [CHUNKSIZE-1:0] rf_res;

logic select_mip;
logic mip_mtip_r;

logic trap_abort_insn;
logic trap_entry_r;
logic trap_pending_r;
logic mcause_30;


assign br_and_taken = (id_instr_any_br & ex_cmp);

assign trap_o = trap_entry_r; //id_except & cntrl_cyc_two;


//  88888888ba     ,ad8888ba,
//  88      "8b   d8"'    `"8b
//  88      ,8P  d8'
//  88aaaaaa8P'  88
//  88""""""'    88
//  88           Y8,
//  88            Y8a.    .a8P
//  88             `"Y8888Y"'

// pc_inc + imm --> TODO: fix offset 1 for RVC
// restrict to mod4 pc in formal proofs
`ifdef RISCV_FORMAL
always_ff @(posedge clk_i) begin
  if (wb_imem_ack_i) assume (pc[1:0] == 2'b0);
end
`endif

logic [31:0]          pc;
logic [CHUNKSIZE-1:0] pc_ser;
logic [CHUNKSIZE-1:0] pc_ser_inc;
logic [CHUNKSIZE-1:0] pc_din;
logic                 pc_inc;

// TODO: check if this optimized optimally

generate
  if ((CONF == "INT") | (CONF == "CSR")) begin
    assign pc_din =   (id_instr_jmp & cntrl_cyc_two)            ? ({{CHUNKSIZE-1{1'b1}}, 1'b0 | ~cntrl_lsb } & spm_d_pc_out) :
                      // TODO: can this be opt?
                      trap_entry_r                              ? rf_rb  :
                      (br_and_taken & cntrl_cyc_two) | id_mret  ? ex_res :
                                                                  pc_ser_inc;
  end else begin

    //assign pc_din =   (id_instr_jmp & cntrl_cyc_two) ? ({{CHUNKSIZE-1{1'b1}}, ~cntrl_lsb } & spm_d_pc_out)  :
    //                  (br_and_taken & cntrl_cyc_two) ? ex_res :
    //                                                  pc_ser_inc;

    // Smaller, apply for CSR as well
    always_comb begin
      pc_din = pc_ser_inc;
      if (cntrl_cyc_two & br_and_taken)
        pc_din = ex_res;
      if (cntrl_cyc_two & id_instr_jmp)
        //pc_din = ({{CHUNKSIZE-1{1'b1}}, ~cntrl_lsb } & spm_d_pc_out);
        pc_din = spm_d_pc_out;
        if (cntrl_lsb)
          pc_din[0] = 1'b0;
    end

  end
endgenerate

fazyrv_pc #( .CHUNKSIZE(CHUNKSIZE), .BOOTADR(BOOTADR) ) i_fazyrv_pc
(
  .clk_i        ( clk_i       ),
  .rst_in       ( rst_in      ),
  .inc_i        ( pc_inc      ), // always inc, maybe overwrite
  .shift_i      ( ~hlt_regs   ),
  .din_i        ( pc_din      ),
  .pc_ser_o     ( pc_ser      ),
  .pc_ser_inc_o ( pc_ser_inc  ),
  .pc_o         ( pc          )
);


//    ,ad8888ba,   888b      88  888888888888  88888888ba   88
//   d8"'    `"8b  8888b     88       88       88      "8b  88
//  d8'            88 `8b    88       88       88      ,8P  88
//  88             88  `8b   88       88       88aaaaaa8P'  88
//  88             88   `8b  88       88       88""""88'    88
//  Y8,            88    `8b 88       88       88    `8b    88
//   Y8a.    .a8P  88     `8888       88       88     `8b   88
//    `"Y8888Y"'   88      `888       88       88      `8b  88888888888


fazyrv_cntrl #(
  .CHUNKSIZE  ( CHUNKSIZE ),
  .RFTYPE     ( RFTYPE    ),
  .CONF       ( CONF      ),
  .MEMDLY1    ( MEMDLY1   )
) i_fazyrv_cntrl (
  .clk_i            ( clk_i             ),
  .rst_in           ( rst_in            ),
  .abort_i          ( trap_abort_insn   ),
  .pc_noinc_i       ( trap_pending_r    ),

  .lsb_o            ( cntrl_lsb         ),
  .msb_o            ( cntrl_msb         ),
  .icyc_o           ( cntrl_icyc        ),
  .pc_inc_o         ( pc_inc            ),

  .rf_ram_wstb_o    ( rf_ram_wstb_o     ),
  .rf_ram_rstb_o    ( rf_ram_rstb_o     ),

  .imem_stb_o       ( imem_stb          ),
  .imem_ack_i       ( wb_imem_ack_i     ),
  .dmem_stb_o       ( dmem_stb          ),
  .dmem_ack_i       ( wb_dmem_ack_i     ),

  .any_jmp_i        ( id_instr_jmp      ),
  .any_br_i         ( id_instr_any_br   ),
  .any_ld_i         ( id_instr_ld       ),
  .any_st_i         ( id_instr_st       ),
  .any_shft_i       ( id_instr_shft     ),
  .any_slt_i        ( id_instr_slt      ),
  .any_csr_i        ( id_instr_csr      ),

  .shft_done_i      ( shft_done         ),

  .cyc_ack_o            ( cntrl_cyc_ack             ),
  .cyc_two_o            ( cntrl_cyc_two             ),
  .cyc_two_shift_next_o ( cntrl_cyc_two_shift_next  ),
  .cyc_shft_o           ( cntrl_cyc_shft            ),

  .hlt_regs_o       ( hlt_regs          ),
  .hlt_spm_a_o      ( hlt_spm_a         ),
  .hlt_imm_o        ( hlt_imm           )
);

//  88  88888888888               d8     88  88b           d88  88888888888  88b           d88
//  88  88                      ,8P'     88  888b         d888  88           888b         d888
//  88  88                     d8"       88  88`8b       d8'88  88           88`8b       d8'88
//  88  88aaaaa              ,8P'        88  88 `8b     d8' 88  88aaaaa      88 `8b     d8' 88
//  88  88"""""             d8"          88  88  `8b   d8'  88  88"""""      88  `8b   d8'  88
//  88  88                ,8P'           88  88   `8b d8'   88  88           88   `8b d8'   88
//  88  88               d8"             88  88    `888'    88  88           88    `888'    88
//  88  88              8P'              88  88     `8'     88  88888888888  88     `8'     88

assign wb_imem_stb_o  = imem_stb;
assign wb_imem_cyc_o  = imem_stb;
assign wb_imem_adr_o  = pc & ~'b11;

//  88888888ba,    88b           d88  88888888888  88b           d88
//  88      `"8b   888b         d888  88           888b         d888
//  88        `8b  88`8b       d8'88  88           88`8b       d8'88
//  88         88  88 `8b     d8' 88  88aaaaa      88 `8b     d8' 88
//  88         88  88  `8b   d8'  88  88"""""      88  `8b   d8'  88
//  88         8P  88   `8b d8'   88  88           88   `8b d8'   88
//  88      .a8P   88    `888'    88  88           88    `888'    88
//  88888888Y"'    88     `8'     88  88888888888  88     `8'     88

assign wb_dmem_adr_o = spm_a_par & ~'b11;
assign wb_dmem_cyc_o = dmem_stb;
assign wb_dmem_stb_o = dmem_stb;
assign wb_dmem_we_o  = id_instr_st;
assign wb_dmem_be_o  = id_ls_mask;

//  88  88888888ba,
//  88  88      `"8b
//  88  88        `8b
//  88  88         88
//  88  88         88
//  88  88         8P
//  88  88      .a8P
//  88  88888888Y"'


logic tmp_dly_r;

always_ff @(posedge clk_i) begin
  tmp_dly_r <= wb_imem_ack_i;
end

generate
  if (MEMDLY1 == 1) begin
    fazyrv_decode_mem1 #(.CHUNKSIZE(CHUNKSIZE), .CONF(CONF), .RFTYPE(RFTYPE)) i_fazyrv_decode
    (
      .clk_i              ( clk_i             ),
      .rst_in             ( rst_in            ),
      .trap_entry_i       ( trap_entry_r      ),
      .adr_lsbs_i         ( spm_a_par[1:0]    ),
      .instr_i            ( wb_imem_dat_i     ),
      .stb_ir_i           ( wb_imem_ack_i     ),
      .stb_cntrl_i        ( tmp_dly_r | cntrl_cyc_two_shift_next  ),
      .cyc_two_i          ( cntrl_cyc_two_shift_next              ),
      .shft_imm_i         ( ~hlt_imm          ),

      .rs1_o              ( id_rs1            ),
      .rs2_o              ( id_rs2            ),
      .rd_o               ( id_rd             ),
      .imm_o              ( id_imm            ),

      .alu_arith_o        ( id_alu_arith      ),
      .alu_en_a_o         ( id_alu_en_a       ),
      .alu_sub_o          ( id_alu_sub        ),
      .alu_xor_o          ( id_alu_xor        ),
      .alu_and_o          ( id_alu_and        ),
      .alu_cmp_sign_o     ( id_alu_cmp_sig    ),
      .alu_cmp_eq_o       ( id_alu_cmp_eq     ),
      .alu_cmp_inv_o      ( id_alu_cmp_inv    ),

      .alu_aux_rev_o      ( id_alu_aux_rev    ),
      .alu_aux_rs_a_pc_o  ( id_aux_rs_a_pc    ),
      .alu_aux_rs_b_imm_o ( id_aux_rs_b_imm   ),
      .alu_aux_b_spm_d_o  ( id_aux_b_spm_d    ),
      .alu_aux_use_cmp_o  ( id_aux_use_cmp    ),

      .ls_mask_o          ( id_ls_mask        ),
      .ld_sext_o          ( id_ld_sext        ),
      .sext_o             ( id_spm_d_sext     ),

      .rf_we_o            ( id_rf_we          ),

      .instr_ld_o         ( id_instr_ld       ),
      .ls_b_o             ( id_ls_b           ),
      .ls_h_o             ( id_ls_h           ),
      .ls_w_o             ( id_ls_w           ),

      .instr_st_o         ( id_instr_st       ),
      .instr_shft_o       ( id_instr_shft     ),
      .instr_left_o       ( id_instr_left     ),
      .instr_any_br_o     ( id_instr_any_br   ),
      .instr_jmp_o        ( id_instr_jmp      ),
      .instr_slt_o        ( id_instr_slt      ),
      .instr_csr_o        ( id_instr_csr      ),

      .csr_hpmtc_o        ( id_csr_hpmtc      ),
      .csr_6_o            ( id_csr_6          ),
      .csr_high_o         ( id_csr_high       ),
      .mret_o             ( id_mret           ),

      .mcause30_o         ( id_mcause30       ),
      .except_o           ( id_except         )
    );
  end else begin
    fazyrv_decode #(.CHUNKSIZE(CHUNKSIZE), .CONF(CONF)) i_fazyrv_decode
    (
      .clk_i              ( clk_i             ),
      .rst_in             ( rst_in            ),
      .trap_entry_i       ( trap_entry_r      ),
      .adr_lsbs_i         ( spm_a_par[1:0]    ),
      .instr_i            ( wb_imem_dat_i     ),
      .stb_ir_i           ( wb_imem_ack_i     ),
      .stb_cntrl_i        ( 'b0               ),
      .cyc_two_i          ( cntrl_cyc_two|cntrl_cyc_shft|wb_imem_stb_o ),
      .shft_imm_i         ( ~hlt_imm          ),

      .rs1_o              ( id_rs1            ),
      .rs2_o              ( id_rs2            ),
      .rd_o               ( id_rd             ),
      .imm_o              ( id_imm            ),

      .alu_arith_o        ( id_alu_arith      ),
      .alu_en_a_o         ( id_alu_en_a       ),
      .alu_sub_o          ( id_alu_sub        ),
      .alu_xor_o          ( id_alu_xor        ),
      .alu_and_o          ( id_alu_and        ),
      .alu_cmp_sign_o     ( id_alu_cmp_sig    ),
      .alu_cmp_eq_o       ( id_alu_cmp_eq     ),
      .alu_cmp_inv_o      ( id_alu_cmp_inv    ),

      .alu_aux_rev_o      ( id_alu_aux_rev    ),
      .alu_aux_rs_a_pc_o  ( id_aux_rs_a_pc    ),
      .alu_aux_rs_b_imm_o ( id_aux_rs_b_imm   ),
      .alu_aux_b_spm_d_o  ( id_aux_b_spm_d    ),
      .alu_aux_use_cmp_o  ( id_aux_use_cmp    ),

      .ls_mask_o          ( id_ls_mask        ),
      .ld_sext_o          ( id_ld_sext        ),
      .sext_o             ( id_spm_d_sext     ),

      .rf_we_o            ( id_rf_we          ),

      .instr_ld_o         ( id_instr_ld       ),
      .ls_b_o             ( id_ls_b           ),
      .ls_h_o             ( id_ls_h           ),
      .ls_w_o             ( id_ls_w           ),

      .instr_st_o         ( id_instr_st       ),
      .instr_shft_o       ( id_instr_shft     ),
      .instr_left_o       ( id_instr_left     ),
      .instr_any_br_o     ( id_instr_any_br   ),
      .instr_jmp_o        ( id_instr_jmp      ),
      .instr_slt_o        ( id_instr_slt      ),
      .instr_csr_o        ( id_instr_csr      ),

      .csr_hpmtc_o        ( id_csr_hpmtc      ),
      .csr_6_o            ( id_csr_6          ),
      .csr_high_o         ( id_csr_high       ),
      .mret_o             ( id_mret           ),

      .mcause30_o         ( id_mcause30       ),
      .except_o           ( id_except         )
    );
  end
endgenerate


// 8888888b.  8888888888 .d8888b.
// 888   Y88b 888       d88P  Y88b
// 888    888 888       888    888
// 888   d88P 8888888   888        .d8888b
// 8888888P"  888       888  88888 88K
// 888 T88b   888       888    888 "Y8888b
// 888  T88b  888       Y88b  d88P      K88
// 888   T88b 8888888888 "Y8888P88  88888P


assign rf_res = id_aux_use_cmp  ? { {CHUNKSIZE-1{1'b0}}, (cntrl_lsb & ex_cmp) } :
                                  ex_res;

assign rf_shft_o  = ~hlt_regs;
assign rf_rs1_o   = id_rs1;
assign rf_rs2_o   = id_rs2;
assign rf_rd_o    = id_rd;
// don't foward writes to mip; should be optimized through id_csr_6
assign select_mip = (id_instr_csr & ~id_rs2[0] & id_rs2[2] & id_csr_6);
assign rf_we_o    = id_rf_we & ~select_mip & ~trap_abort_insn;
assign rf_res_o   = rf_res;

assign rf_ra      = rf_ra_i;
assign rf_rb      = rf_rb_i;

assign rf_hpmtc_o = id_csr_hpmtc;

// TODO: opt?
assign rf_csr_o   = id_instr_csr & (~cntrl_cyc_two | cntrl_lsb) & (~imem_stb);
assign rf_csr_6_o = id_csr_6;


//    ,d
//    88
//  MM88MMM  8b,dPPYba,  ,adPPYYba,  8b,dPPYba,
//    88     88P'   "Y8  ""     `Y8  88P'    "8a
//    88     88          ,adPPPPP88  88       d8
//    88,    88          88,    ,88  88b,   ,a8"
//    "Y888  88          `"8bbdP"Y8  88`YbbdP"'
//                                   88
//                                   88

// TODO: option to latch interrupt (?)

generate
  if ((CONF == "CSR") | (CONF == "INT")) begin

    assign rf_trap_o        = trap_entry_r;
    assign rf_mret_o        = id_mret;
    assign rf_mcause30_o    = id_mcause30;  // overwrite in regfile with timer irq when int==1
    assign rf_mcause_int_o  = ~id_except;

    // TODO: add exc_misalngd; does abort work pause already at eo icyc?
    // TODO: jumping to misaligned insn?

    // For exceptions: don't finish the instrction: complete ICYC1 to have the
    // same pc in the next decode, but do not write any CSRs.
    // contrast: insn is finished on an interrupt request.
    assign trap_abort_insn  = (id_except | (wb_dmem_stb_o & exc_misalngd)) & ~trap_entry_r;

    always_ff @(posedge clk_i) begin
      if (~rst_in) begin
        mip_mtip_r <= 1'b0;
      end else begin
        if (wb_imem_stb_o & tirq_i) begin
          mip_mtip_r <= 1'b1;
        end
        // TODO: writes to mip
        if (wb_imem_ack_i & trap_entry_r & ~id_except) begin
          mip_mtip_r <= 1'b0;
        end
      end
    end

    // TODO: reads from mip
    always_ff @(posedge clk_i) begin
      if (~rst_in) begin
        trap_entry_r    <= 1'b0;
        trap_pending_r  <= 1'b0;
      end else begin
        if ((mip_mtip_r | id_except | (wb_dmem_stb_o & exc_misalngd)) & ~trap_entry_r) begin
          trap_pending_r <= 1'b1;
        end

        if (wb_imem_ack_i) begin
          trap_pending_r  <= 1'b0;
          trap_entry_r    <= trap_pending_r;
        end
      end
    end

  end else begin
    assign trap_abort_insn  = 1'b0;
    assign trap_entry_r     = 1'b0;
    assign trap_pending_r   = 1'b0;
    assign mip_mtip_r       = 1'b0;

    assign rf_trap_o        = 1'b0;
    assign rf_mret_o        = 1'b0;
    assign rf_mcause30_o    = 2'b0;
    assign rf_mcause_int_o  = 1'b0;
  end
endgenerate

// Always shifted in spm_a
//
assign spm_a_ser = id_instr_shft ? ex_rb_mxd : ex_res;

fazyrv_spm_a #( .CHUNKSIZE(CHUNKSIZE) ) i_fazyrv_spm_a
(
  .clk_i  ( clk_i         ),
  .shft_i ( ~hlt_spm_a    ),
  .ser_i  ( spm_a_ser     ),
  .par_o  ( spm_a_par     )
);

assign spm_d_ld_par = id_instr_ld & wb_dmem_ack_i;


fazyrv_spm_d #( .CHUNKSIZE(CHUNKSIZE), .CONF(CONF) ) i_fazyrv_spm_d
(
  .clk_i        ( clk_i           ),
  .ld_par_i     ( spm_d_ld_par    ),

  .adr_lsbs_i   ( spm_a_par[1:0]  ),

  .instr_ld_i   ( id_instr_ld     ),
  .instr_st_i   ( id_instr_st     ),
  .ls_b_i       ( id_ls_b         ),
  .ls_h_i       ( id_ls_h         ),
  .ls_w_i       ( id_ls_w         ),

  .arith_i      ( id_spm_d_sext   ),

  .shft_op_i    ( id_instr_shft   ),
  .left_i       ( id_instr_left   ),
  .shamt_i      ( spm_a_par[CHUNKSIZE+4:CHUNKSIZE] ),
  .done_o       ( shft_done       ),

  .icyc_i       ( cntrl_icyc      ),
  .icyc_lsb_i   ( cntrl_lsb       ),
  .icyc_msb_i   ( cntrl_msb       ),

  .cyc_rd_i     ( cntrl_cyc_two   ),
  .cyc_wt_i     ( cntrl_cyc_ack   ),
  .cyc_shft_i   ( cntrl_cyc_shft  ),

  .misalngd_o   ( exc_misalngd    ),

  .ser_i        ( ex_res          ),
  .ser_o        ( spm_d_dout      ),
  .ser_pc_o     ( spm_d_pc_out    ),

  .pdin_i       ( wb_dmem_dat_i   ),
  .pdout_o      ( wb_dmem_dat_o   )
);

// 8888888888 Y88b   d88P
// 888         Y88b d88P
// 888          Y88o88P
// 8888888       Y888P
// 888           d888b
// 888          d88888b
// 888         d88P Y88b
// 8888888888 d88P   Y88b

logic csr_swap_high;

generate
if (CONF == "CSR") begin
  assign csr_swap_high = id_instr_csr & id_csr_high & id_csr_hpmtc;
end else begin
  assign csr_swap_high = 1'b0;
end
endgenerate

assign ex_ra_mxd =  id_aux_rs_a_pc   ?  pc_ser      : rf_ra;
assign ex_rb_mxd =  id_aux_rs_b_imm  ?  id_imm      :
                    id_aux_b_spm_d   ?  spm_d_dout  :
                                        rf_rb;

assign ex_ra  = (id_alu_aux_rev ^ csr_swap_high) ? ex_rb_mxd : ex_ra_mxd;
assign ex_rb  = (id_alu_aux_rev ^ csr_swap_high) ? ex_ra_mxd : ex_rb_mxd;
assign ex_cmp = ex_cmp_tmp ^ id_alu_cmp_inv;

fazyrv_alu #( .CHUNKSIZE(CHUNKSIZE) ) i_fazyrv_alu
(
  .clk_i        ( clk_i           ),
  .lsb_i        ( cntrl_lsb       ),
  .msb_i        ( cntrl_msb       ),

  .rs_a_i       ( ex_ra           ),
  .rs_b_i       ( ex_rb           ),
  .res_o        ( ex_res          ),
  .cmp_o        ( ex_cmp_tmp      ),

  .sel_arith_i  ( id_alu_arith    ),
  .en_a_i       ( id_alu_en_a     ),
  .op_sub_i     ( id_alu_sub      ),
  .op_xor_i     ( id_alu_xor      ),
  .op_and_i     ( id_alu_and      ),

  .cmp_signd_i  ( id_alu_cmp_sig  ),
  .cmp_eq_i     ( id_alu_cmp_eq   ),
  .cmp_keep_i   ( cntrl_cyc_two   )
);

//  8888888b.  8888888888 888888b.   888     888  .d8888b.
//  888  "Y88b 888        888  "88b  888     888 d88P  Y88b
//  888    888 888        888  .88P  888     888 888    888
//  888    888 8888888    8888888K.  888     888 888
//  888    888 888        888  "Y88b 888     888 888  88888
//  888    888 888        888    888 888     888 888    888
//  888  .d88P 888        888   d88P Y88b. .d88P Y88b  d88P
//  8888888P"  8888888888 8888888P"   "Y88888P"   "Y8888P88

`ifdef DEBUG

(* keep *) logic         dbg_new_insn;
(* keep *) logic [127:0] dbg_ascii_insn_old_r;
(* keep *) logic [127:0] dbg_ascii_insn_r;
(* keep *) logic [127:0] dbg_ascii_insn_n;

(* keep *) logic [31:0] dbg_addr_r;
(* keep *) logic [31:0] dbg_addr_old_r;
(* keep *) logic [31:0] dbg_insn_r;

(* keep *) logic [31:0] dbg_id_imm;

assign dbg_new_insn = rst_in & wb_imem_ack_i;

always_ff @(posedge clk_i) begin
  if (dbg_new_insn) begin
    dbg_addr_r <= wb_imem_adr_o;

    dbg_insn_r <= wb_imem_dat_i;

    // Overwrite in the case of trap entry with
    // a pseudo instruction such that riscv-formal
    // does not put the target isntruction to be checked
    // in this cycle and fails.
    if (trap_pending_r | trap_entry_r)
      dbg_insn_r <= 'b0;

    dbg_ascii_insn_r      <= dbg_ascii_insn_n;
    dbg_addr_old_r        <= dbg_addr_r;
    dbg_ascii_insn_old_r  <= dbg_ascii_insn_r;
  end
end

//                         30    25    20    15    10     5     0
//                          |     |     |     |     |     |     |
`define INSTR_LUI     (32'b??_?????_?????_?????_?????_???01_10111)
`define INSTR_AUIPC   (32'b??_?????_?????_?????_?????_???00_10111)
`define INSTR_JAL     (32'b??_?????_?????_?????_?????_???11_01111)
`define INSTR_JALR    (32'b??_?????_?????_?????_000??_???11_00111)
`define INSTR_BEQ     (32'b??_?????_?????_?????_000??_???11_00011)
`define INSTR_BNE     (32'b??_?????_?????_?????_001??_???11_00011)
`define INSTR_BLT     (32'b??_?????_?????_?????_100??_???11_00011)
`define INSTR_BGE     (32'b??_?????_?????_?????_101??_???11_00011)
`define INSTR_BLTU    (32'b??_?????_?????_?????_110??_???11_00011)
`define INSTR_BGEU    (32'b??_?????_?????_?????_111??_???11_00011)
`define INSTR_LB      (32'b??_?????_?????_?????_000??_???00_00011)
`define INSTR_LH      (32'b??_?????_?????_?????_001??_???00_00011)
`define INSTR_LW      (32'b??_?????_?????_?????_010??_???00_00011)
`define INSTR_LBU     (32'b??_?????_?????_?????_100??_???00_00011)
`define INSTR_LHU     (32'b??_?????_?????_?????_101??_???00_00011)
`define INSTR_SB      (32'b??_?????_?????_?????_000??_???01_00011)
`define INSTR_SH      (32'b??_?????_?????_?????_001??_???01_00011)
`define INSTR_SW      (32'b??_?????_?????_?????_010??_???01_00011)
`define INSTR_ADDI    (32'b??_?????_?????_?????_000??_???00_10011)
`define INSTR_SLTI    (32'b??_?????_?????_?????_010??_???00_10011)
`define INSTR_SLTIU   (32'b??_?????_?????_?????_011??_???00_10011)
`define INSTR_XORI    (32'b??_?????_?????_?????_100??_???00_10011)
`define INSTR_ORI     (32'b??_?????_?????_?????_110??_???00_10011)
`define INSTR_ANDI    (32'b??_?????_?????_?????_111??_???00_10011)
`define INSTR_SLLI    (32'b00_00000_?????_?????_001??_???00_10011)
`define INSTR_SRLI    (32'b00_00000_?????_?????_101??_???00_10011)
`define INSTR_SRAI    (32'b01_00000_?????_?????_101??_???00_10011)
`define INSTR_ADD     (32'b00_00000_?????_?????_000??_???01_10011)
`define INSTR_SUB     (32'b01_00000_?????_?????_000??_???01_10011)
`define INSTR_SLL     (32'b00_00000_?????_?????_001??_???01_10011)
`define INSTR_SLT     (32'b00_00000_?????_?????_010??_???01_10011)
`define INSTR_SLTU    (32'b00_00000_?????_?????_011??_???01_10011)
`define INSTR_XOR     (32'b00_00000_?????_?????_100??_???01_10011)
`define INSTR_SRL     (32'b00_00000_?????_?????_101??_???01_10011)
`define INSTR_SRA     (32'b01_00000_?????_?????_101??_???01_10011)
`define INSTR_OR      (32'b00_00000_?????_?????_110??_???01_10011)
`define INSTR_AND     (32'b00_00000_?????_?????_111??_???01_10011)
`define INSTR_ECALL   (32'b??_0????_????0_?????_000??_???11_10011)
`define INSTR_EBREAK  (32'b??_0????_????1_?????_000??_???11_10011)
`define INSTR_CSRRW   (32'b??_?????_?????_?????_001??_???11_10011)
`define INSTR_CSRRS   (32'b??_?????_?????_?????_010??_???11_10011)
`define INSTR_CSRRC   (32'b??_?????_?????_?????_011??_???11_10011)
`define INSTR_CSRRWI  (32'b??_?????_?????_?????_101??_???11_10011)
`define INSTR_CSRRSI  (32'b??_?????_?????_?????_110??_???11_10011)
`define INSTR_CSRRCI  (32'b??_?????_?????_?????_111??_???11_10011)
`define INSTR_MRET    (32'b??_1????_?????_?????_000??_???11_10011)

always_comb begin
  casez(wb_imem_dat_i)
    `INSTR_LUI:     dbg_ascii_insn_n = "lui";
    `INSTR_AUIPC:   dbg_ascii_insn_n = "auipc";
    `INSTR_JAL:     dbg_ascii_insn_n = "jal";
    `INSTR_JALR:    dbg_ascii_insn_n = "jalr";
    `INSTR_BEQ:     dbg_ascii_insn_n = "beq";
    `INSTR_BNE:     dbg_ascii_insn_n = "bne";
    `INSTR_BLT:     dbg_ascii_insn_n = "blt";
    `INSTR_BGE:     dbg_ascii_insn_n = "bge";
    `INSTR_BLTU:    dbg_ascii_insn_n = "bltu";
    `INSTR_BGEU:    dbg_ascii_insn_n = "bgeu";
    `INSTR_BEQ:     dbg_ascii_insn_n = "beq";
    `INSTR_BNE:     dbg_ascii_insn_n = "bne";
    `INSTR_BLT:     dbg_ascii_insn_n = "blt";
    `INSTR_BGE:     dbg_ascii_insn_n = "bge";
    `INSTR_BLTU:    dbg_ascii_insn_n = "bltu";
    `INSTR_BGEU:    dbg_ascii_insn_n = "bgeu";
    `INSTR_LB:      dbg_ascii_insn_n = "lb";
    `INSTR_LH:      dbg_ascii_insn_n = "lh";
    `INSTR_LW:      dbg_ascii_insn_n = "lw";
    `INSTR_LBU:     dbg_ascii_insn_n = "lbu";
    `INSTR_LHU:     dbg_ascii_insn_n = "lhu";
    `INSTR_SB:      dbg_ascii_insn_n = "sb";
    `INSTR_SH:      dbg_ascii_insn_n = "sh";
    `INSTR_SW:      dbg_ascii_insn_n = "sw";
    `INSTR_ADDI:    dbg_ascii_insn_n = "addi";
    `INSTR_SLTI:    dbg_ascii_insn_n = "slti";
    `INSTR_SLTIU:   dbg_ascii_insn_n = "sltiu";
    `INSTR_XORI:    dbg_ascii_insn_n = "xori";
    `INSTR_ORI:     dbg_ascii_insn_n = "ori";
    `INSTR_ANDI:    dbg_ascii_insn_n = "andi";
    `INSTR_SLLI:    dbg_ascii_insn_n = "slli";
    `INSTR_SRLI:    dbg_ascii_insn_n = "srli";
    `INSTR_SRAI:    dbg_ascii_insn_n = "srai";
    `INSTR_ADD:     dbg_ascii_insn_n = "add";
    `INSTR_SUB:     dbg_ascii_insn_n = "sub";
    `INSTR_SLL:     dbg_ascii_insn_n = "sll";
    `INSTR_SLT:     dbg_ascii_insn_n = "slt";
    `INSTR_SLTU:    dbg_ascii_insn_n = "sltu";
    `INSTR_XOR:     dbg_ascii_insn_n = "xor";
    `INSTR_SRL:     dbg_ascii_insn_n = "srl";
    `INSTR_SRA:     dbg_ascii_insn_n = "sra";
    `INSTR_OR:      dbg_ascii_insn_n = "or";
    `INSTR_AND:     dbg_ascii_insn_n = "and";
    `INSTR_CSRRW:   dbg_ascii_insn_n = "csrrw";
    `INSTR_CSRRS:   dbg_ascii_insn_n = "csrrs";
    `INSTR_CSRRC:   dbg_ascii_insn_n = "csrrc";
    `INSTR_CSRRW:   dbg_ascii_insn_n = "csrrw";
    `INSTR_CSRRS:   dbg_ascii_insn_n = "csrrs";
    `INSTR_CSRRC:   dbg_ascii_insn_n = "csrrc";
    `INSTR_CSRRWI:  dbg_ascii_insn_n = "csrrwi";
    `INSTR_CSRRSI:  dbg_ascii_insn_n = "csrrsi";
    `INSTR_CSRRCI:  dbg_ascii_insn_n = "csrrci";
    `INSTR_ECALL:   dbg_ascii_insn_n = "ecall";
    `INSTR_EBREAK:  dbg_ascii_insn_n = "ebreak";
    `INSTR_MRET:    dbg_ascii_insn_n = "mret";
    default:        dbg_ascii_insn_n = "illegal";
  endcase

  if (trap_entry_r)
    dbg_ascii_insn_n = "entertrap";
end
`endif


//  8888888888 .d88888b.  8888888b.  888b     d888        d8888 888
//  888       d88P" "Y88b 888   Y88b 8888b   d8888       d88888 888
//  888       888     888 888    888 88888b.d88888      d88P888 888
//  8888888   888     888 888   d88P 888Y88888P888     d88P 888 888
//  888       888     888 8888888P"  888 Y888P 888    d88P  888 888
//  888       888     888 888 T88b   888  Y8P  888   d88P   888 888
//  888       Y88b. .d88P 888  T88b  888   "   888  d8888888888 888
//  888        "Y88888P"  888   T88b 888       888 d88P     888 88888888

`ifdef RISCV_FORMAL

(* keep *) logic fv_first_fetched_r;
(* keep *) logic fv_first_decoded_r;

logic [31:0] fv_ra_r;
logic [31:0] fv_rb_r;

always_ff @(posedge clk_i) begin
  if (~rst_in) begin
    fv_ra_r   <= 'b0;
    fv_rb_r   <= 'b0;
  end else begin
    if (rf_shft_o & ~cntrl_cyc_two) begin
      fv_ra_r   <= {rf_ra_i, fv_ra_r[31:CHUNKSIZE]};
      fv_rb_r   <= {rf_rb_i, fv_rb_r[31:CHUNKSIZE]};
    end
  end
end

always_ff @(posedge clk_i) begin

  if (~rst_in) begin
    fv_first_fetched_r <= 'b0;
    fv_first_decoded_r <= 'b0;
  end

  if (~fv_first_fetched_r & rst_in) begin
    fv_first_fetched_r <= wb_imem_ack_i;
  end

  if (~fv_first_decoded_r & rst_in) begin
    fv_first_decoded_r <= fv_first_fetched_r;
  end

  rvfi_valid <= rst_in & imem_stb & wb_imem_ack_i & 
                fv_first_fetched_r & fv_first_decoded_r;

  if (rvfi_valid)
    rvfi_order      <= rvfi_order + {63'd0, rvfi_valid};
  else
    rvfi_order      <= rvfi_order;

  rvfi_insn         <= dbg_insn_r;


  logic fv_trap_pending_r;

  logic stage_dec_r;

  stage_dec_r <= wb_imem_ack_i;

  if (wb_imem_ack_i | stage_dec_r) begin
    fv_trap_pending_r <= 1'b0;
  end else if (id_except | (wb_dmem_stb_o & exc_misalngd)) begin
    fv_trap_pending_r <= 1'b1;
  end
  
  // Workaroung for riscv-formal if no traps are implemented
  //
  if ((CONF == "CSR") | (CONF == "INT")) begin
    rvfi_trap     <= trap_pending_r | trap_entry_r;
  end else begin
    rvfi_trap     <= fv_trap_pending_r;
  end

  rvfi_halt       <= 1'b0;
  rvfi_intr       <= 1'b0;
  rvfi_mode       <= 2'd3;
  rvfi_ixl        <= 2'd1;

  rvfi_rs1_addr   <= id_rs1;
  rvfi_rs1_rdata  <= fv_ra_r;
  
  rvfi_rs2_addr   <= id_rs2 & {5{~id_instr_ld}};
  rvfi_rs2_rdata  <= fv_rb_r & {REG_WIDTH{~id_instr_ld}};
  // rvfi_rd_wdata in top directly from rf;

  logic fv_rf_we;
  
  if (rvfi_valid | id_instr_any_br | id_instr_st) begin
    rvfi_rd_addr    <= 'b0;
    fv_rf_we        <= 'b0;
  end else if (id_rf_we | fv_rf_we) begin
    fv_rf_we        <= 'b1;
    rvfi_rd_addr    <= id_rd;
  end

  rvfi_pc_rdata   <= dbg_addr_r;

  if (rvfi_valid | ~rst_in) begin
    rvfi_mem_addr   <= 'b0;
    rvfi_mem_rmask  <= 'b0;
    rvfi_mem_wmask  <= 'b0;
    rvfi_mem_rdata  <= 'b0;
    rvfi_mem_wdata  <= 'b0;
  end

 if (wb_dmem_ack_i) begin
    rvfi_mem_addr   <= wb_dmem_adr_o;
    rvfi_mem_rmask  <= wb_dmem_we_o ? 4'b0000 : wb_dmem_be_o;
    rvfi_mem_wmask  <= wb_dmem_we_o ? wb_dmem_be_o : 4'b0000;

    if (wb_dmem_we_o) begin
      rvfi_mem_wdata  <= wb_dmem_dat_o;
    end else begin
      rvfi_mem_rdata  <= wb_dmem_dat_i;
    end
  end
end

// adopted from SERV
always @(wb_imem_adr_o)
  rvfi_pc_wdata <= wb_imem_adr_o;

`endif

endmodule

