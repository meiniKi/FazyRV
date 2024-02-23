// Copyright (c) 2023 - 2024 Meinhard Kissich
// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
// File  :  fazyrv_spm_d.sv
// Usage :  Scratchpad memory for data.
//
// Param
//  - CHUNKSIZE   Data path width of the core.
//  - CONF        Configuration of the processor (MIN, INT, or CSR).
//  - ICYC        Number of cylces one icycle pass takes.
//
// Ports
//  - clk_i       Clock input, sensitive to rising edge.
//  - ld_par_i    Load from parallel interface into the register.
//
//  - adr_lsbs_i  Lowest two bits of the address for alignment.
//
//  - instr_ld_i  Current instruction is a load.
//  - instr_st_i  Current instruction is a store.
//  - ls_b_i      If load or store then consider byte.
//  - ls_h_i      If load or store then consider half word.
//  - ls_w_i      If load or store then consider word.
//
//  - arith_i     Arithmatic shift.
//
//  - shft_op_i   Current instructions is a shift.
//  - left_i      Shift direction left.
//  - shamt_i     Shift amount in bits.
//  - done_o      Shift operations are done, can process.
//
//  - icyc_i      Number of chunk in cycle.
//  - icyc_lsb_i  Current cycle contains the LSB.
//  - icyc_msb_i  Current cycle contains the MSB.
//
//  - cyc_rd_i    In cycle that reads spm_d.
//  - cyc_wt_i    In cycle that waits for dmem ack.
//  - cyc_shft_i  In cycle that waits for shift to be done.
//
//  - misalngd_o  Misaligned exception.
//
//  - ser_i       Serial input data part.
//  - ser_o       Serial output data part.
//  - ser_pc_o    Serial output if used to update the pc.
//
//  - pdin_i      Parallel input data.
//  - pdout_o     Parallel output data.
//
// Reset
//  - Make sure msb_i is high for at least one cycle before use.
//  - Make sure enough cycles have been passed s.t. shamt_r is zero.
//
// Constraints
//  - left_i == 0 for load operations.
//  - Loop data back while waiting for shift to be done.
//  - arith == sext for loads.
// -----------------------------------------------------------------------------

module fazyrv_spm_d #(
  parameter CHUNKSIZE = 2,
  parameter CONF      = "MIN",
  parameter ICYC      = (32 / CHUNKSIZE)
) (
  input  logic                    clk_i,
  input  logic                    ld_par_i,

  input  logic [1:0]              adr_lsbs_i,

  input  logic                    instr_ld_i,
  input  logic                    instr_st_i,
  input  logic                    ls_b_i,
  input  logic                    ls_h_i,
  input  logic                    ls_w_i,

  input  logic                    arith_i,

  input  logic                    shft_op_i,
  input  logic                    left_i,
  input  logic [4:0]              shamt_i,
  output logic                    done_o,

  input  logic [$clog2(ICYC)-1:0] icyc_i,
  input  logic                    icyc_lsb_i,
  input  logic                    icyc_msb_i,

  input  logic                    cyc_rd_i,
  input  logic                    cyc_wt_i,
  input  logic                    cyc_shft_i,

  output logic                    misalngd_o,

  input  logic [CHUNKSIZE-1:0]    ser_i,
  output logic [CHUNKSIZE-1:0]    ser_o,
  output logic [CHUNKSIZE-1:0]    ser_pc_o,

  input  logic [31:0]             pdin_i,
  output logic [31:0]             pdout_o
);

localparam REG_WIDTH  = 32;

logic [REG_WIDTH+CHUNKSIZE-1:0] reg_r, reg_n;
logic [$clog2(CHUNKSIZE+1)-1:0] shft_tap_pos;

logic [$clog2(REG_WIDTH/CHUNKSIZE):0] macro_steps_r = '0;
logic [$clog2(REG_WIDTH/CHUNKSIZE):0] macro_steps_n;

logic [$clog2(REG_WIDTH/CHUNKSIZE):0] macro_steps_ld_left;
logic [$clog2(REG_WIDTH/CHUNKSIZE):0] macro_steps_ld_right;
logic [$clog2(REG_WIDTH/CHUNKSIZE):0] macro_steps_ld_mxd;


logic [4:0]           shamt_mxd_masks;
logic [CHUNKSIZE-1:0] ser;

// --- macro steps ---

/* verilator lint_off WIDTHEXPAND */

assign macro_steps_ld_left  = (REG_WIDTH >> $clog2(CHUNKSIZE))-(shamt_i >> $clog2(CHUNKSIZE));
assign macro_steps_ld_right = (shamt_i >> $clog2(CHUNKSIZE));

logic steps_ld_mod_mask;
logic [$clog2(REG_WIDTH/CHUNKSIZE):0] macro_steps_ld_mxd_pre1;
logic [$clog2(REG_WIDTH/CHUNKSIZE):0] macro_steps_ld_mxd_shft;

assign macro_steps_ld_mxd_pre1 = left_i ? macro_steps_ld_left : macro_steps_ld_right;

assign steps_ld_mod_mask        = macro_steps_ld_mxd_pre1[$clog2(REG_WIDTH/CHUNKSIZE)] & macro_steps_ld_mxd_pre1[0];
assign macro_steps_ld_mxd_shft  = macro_steps_ld_mxd_pre1 | {$clog2(REG_WIDTH/CHUNKSIZE)+1{steps_ld_mod_mask}};

assign macro_steps_ld_mxd = instr_ld_i ? ((adr_lsbs_i << ($clog2(8 >> $clog2(CHUNKSIZE))) ) - 'b1) : macro_steps_ld_mxd_shft;

// optimized version of &macro_steps_n;
assign done_o = macro_steps_n[$clog2(REG_WIDTH/CHUNKSIZE)] & macro_steps_n[0];

assign macro_steps_n = cyc_shft_i ? (macro_steps_r - 'b1) : macro_steps_ld_mxd;

always_ff @(posedge clk_i) begin
  macro_steps_r <= macro_steps_n;
end

// --- micro steps & masks & replicant ---

logic [CHUNKSIZE-1:0] micro_mask_left;
logic [CHUNKSIZE-1:0] micro_mask_right;
logic [CHUNKSIZE-1:0] micro_mask_mxd;

logic [CHUNKSIZE-1:0] micro_cap_mask;

logic repl_src;
logic repl_r;
logic repl;
logic repl_cap;

// mask that has shamt%CHUNKSIZE 1s at LSB then 0s
assign micro_mask_left = (('b1 << (shamt_mxd_masks & (CHUNKSIZE-1)) ) - 'b1);

genvar i;
generate
  for (i = 0; i < CHUNKSIZE; i = i + 1) begin
    assign micro_mask_right[i] = micro_mask_left[CHUNKSIZE-1-i];
  end
endgenerate

assign micro_mask_mxd = left_i ? micro_mask_left : micro_mask_right;

logic [$clog2(REG_WIDTH/CHUNKSIZE)-1:0] macro_mask_apply_cyc;
logic [$clog2(REG_WIDTH/CHUNKSIZE)-1:0] macro_repl_apply_cyc;
logic macro_repl_apply;

assign shamt_mxd_masks = instr_ld_i ? {ls_b_i|ls_h_i, ls_b_i, 3'b0} : shamt_i;

assign macro_mask_apply_cyc = left_i      ? macro_steps_ld_right :
                              instr_ld_i  ? (REG_WIDTH/CHUNKSIZE) - 'd1 - ({ls_b_i|ls_h_i, ls_b_i, 3'b0} >> $clog2(CHUNKSIZE)) :
                                             macro_steps_ld_left - 'd1;

assign macro_repl_apply_cyc = macro_mask_apply_cyc;

assign macro_repl_apply = left_i ? (icyc_i <= macro_repl_apply_cyc) : (icyc_i > macro_repl_apply_cyc);


assign repl_cap       = (icyc_i == macro_repl_apply_cyc);
assign micro_cap_mask = (arith_i<<(CHUNKSIZE-1)) >> (shamt_mxd_masks & (CHUNKSIZE-1));
assign repl_src       = |(ser & micro_cap_mask);

// forwarding
assign repl           = ((repl_cap & repl_src) | repl_r);

always_ff @(posedge clk_i) begin
  if (~cyc_rd_i) begin
    repl_r <= 1'b0;
  end else if (repl_cap) begin
    repl_r <= repl_src;
  end
end

// --- input and state ---

assign reg_n  =  ld_par_i ? {{CHUNKSIZE{1'bx}}, pdin_i}  :
                            {ser_i, reg_r[REG_WIDTH+CHUNKSIZE-1:CHUNKSIZE]};


// Stop shifting when store data is in the rigth position
// TODO: merge this with macro steps, as those are not required when storing

logic [$clog2(REG_WIDTH/CHUNKSIZE):0] hlt_reg_after;
logic hlt_reg;

assign hlt_reg_after =  (instr_st_i & ls_b_i)                 ? ((32-8*adr_lsbs_i)/CHUNKSIZE)-'b1  :
                        (instr_st_i & ls_h_i & adr_lsbs_i[1]) ? (16/CHUNKSIZE)-'b1                 :
                                                                '1;

// TODO: replace with &, check area changes
assign hlt_reg = (icyc_i > hlt_reg_after);


always_ff @(posedge clk_i) begin
  // TODO: check this logic (can it be opt?)
  if (~hlt_reg & (~cyc_wt_i | ld_par_i | cyc_rd_i | (~cyc_rd_i & ~cyc_wt_i & ~cyc_shft_i))) begin
    reg_r <= reg_n;
  end
end

// --- output ---

// Move this to spm_a?
generate
if (CONF != "MIN")
  assign misalngd_o = ((|adr_lsbs_i) & ls_w_i) | (adr_lsbs_i[0] & ls_h_i);
else
`ifndef RISCV_FORMAL
  assign misalngd_o = 'b0;
`else
// Generate for Framework, because the ls masks are not restricted to
// aligned accesses otherwise
  assign misalngd_o = ((|adr_lsbs_i) & ls_w_i) | (adr_lsbs_i[0] & ls_h_i);
`endif
endgenerate

assign shft_tap_pos = left_i ? (CHUNKSIZE - (shamt_mxd_masks & (CHUNKSIZE-1))) : (shamt_mxd_masks & (CHUNKSIZE-1));

assign ser    =  cyc_rd_i ? reg_r[shft_tap_pos +: CHUNKSIZE] : reg_r[CHUNKSIZE +: CHUNKSIZE];

// opt?
assign ser_o =  cyc_shft_i                        ? reg_r[CHUNKSIZE-1:0]                                            :
                (macro_mask_apply_cyc == icyc_i)  ? (ser & ~micro_mask_mxd) | ({CHUNKSIZE{repl}} & micro_mask_mxd)  :
                 macro_repl_apply                 ? {CHUNKSIZE{repl}}                                               :
                                                    ser;

assign ser_pc_o = reg_r[CHUNKSIZE +: CHUNKSIZE];
assign pdout_o  = reg_r[CHUNKSIZE +: 32];

/* verilator lint_on WIDTHEXPAND */
endmodule

