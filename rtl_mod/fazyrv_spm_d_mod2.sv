// Copyright (c) 2023 Meinhard Kissich
// -----------------------------------------------------------------------------
// File  :  fazyrv_spm_d.v
// Usage :  Scratchpad memory for data.
// -----------------------------------------------------------------------------

module fazyrv_spm_d #(
  parameter BWIDTH  = 1,
  parameter NO_ICYC = (32 / BWIDTH),
  parameter CONF    = "MIN"
) (
  input  logic                        clk_i,
  input  logic                        ld_par_i,

  input  logic [1:0]                  adr_lsbs_i,

  input  logic                        instr_ld_i,
  input  logic                        instr_st_i,
  input  logic                        ls_b_i,
  input  logic                        ls_h_i,
  input  logic                        ls_w_i,

  input  logic                        arith_i,

  input  logic                        shft_op_i,
  input  logic                        left_i,
  input  logic [4:0]                  shamt_i,
  output logic                        done_o,

  input  logic [$clog2(NO_ICYC)-1:0]  icyc_i,
  input  logic                        icyc_lsb_i,
  input  logic                        icyc_msb_i,

  input  logic                        cyc_rd_i,
  input  logic                        cyc_wt_i,
  input  logic                        cyc_shft_i,

  output logic                        misalngd_o,

  input  logic [BWIDTH-1:0]           ser_i,
  output logic [BWIDTH-1:0]           ser_o,
  output logic [BWIDTH-1:0]           ser_pc_o,

  input  logic [31:0]                 pdin_i,
  output logic [31:0]                 pdout_o
);

localparam REG_WIDTH  = 32;

logic [REG_WIDTH+BWIDTH-1:0] reg_r, reg_n;
logic [$clog2(BWIDTH+1)-1:0] shft_tap_pos;

logic [$clog2(REG_WIDTH/BWIDTH):0] macro_steps_r = '0;
logic [$clog2(REG_WIDTH/BWIDTH):0] macro_steps_n;

logic [$clog2(REG_WIDTH/BWIDTH):0] macro_steps_ld_left;
logic [$clog2(REG_WIDTH/BWIDTH):0] macro_steps_ld_right;
logic [$clog2(REG_WIDTH/BWIDTH):0] macro_steps_ld_mxd;


logic [4:0]         shamt_mxd_masks;
logic [BWIDTH-1:0]  ser;

// --- macro steps ---

/* verilator lint_off WIDTHEXPAND */


assign macro_steps_ld_left  = (REG_WIDTH >> $clog2(BWIDTH))-(shamt_i >> $clog2(BWIDTH));
assign macro_steps_ld_right = (shamt_i >> $clog2(BWIDTH));


logic steps_ld_mod_mask;
logic [$clog2(REG_WIDTH/BWIDTH):0] macro_steps_ld_mxd_pre1;
logic [$clog2(REG_WIDTH/BWIDTH):0] macro_steps_ld_mxd_shft;

assign macro_steps_ld_mxd_pre1 = left_i ? macro_steps_ld_left : macro_steps_ld_right;

assign steps_ld_mod_mask        = macro_steps_ld_mxd_pre1[$clog2(REG_WIDTH/BWIDTH)] & macro_steps_ld_mxd_pre1[0];
assign macro_steps_ld_mxd_shft  = macro_steps_ld_mxd_pre1 | {$clog2(REG_WIDTH/BWIDTH)+1{steps_ld_mod_mask}};

assign macro_steps_ld_mxd = instr_ld_i ? ((adr_lsbs_i << ($clog2(8 >> $clog2(BWIDTH))) ) - 'b1) : macro_steps_ld_mxd_shft;

// optimized version of &macro_steps_n;
assign done_o = macro_steps_n[$clog2(REG_WIDTH/BWIDTH)] & macro_steps_n[0];

assign macro_steps_n = cyc_shft_i ? (macro_steps_r - 'b1) : macro_steps_ld_mxd;

always_ff @(posedge clk_i) begin
  macro_steps_r <= macro_steps_n;
end

// --- micro steps & masks & replicant ---

logic [BWIDTH-1:0] micro_mask_left;
logic [BWIDTH-1:0] micro_mask_right;
logic [BWIDTH-1:0] micro_mask_mxd;

logic [BWIDTH-1:0] micro_cap_mask;

logic repl_src;
logic repl_r;
logic repl;
logic repl_cap;


// mask that has shamt%BWIDTH 1s at LSB then 0s
assign micro_mask_left = (('b1 << (shamt_mxd_masks & (BWIDTH-1)) ) - 'b1);

genvar i;
generate
  for (i = 0; i < BWIDTH; i = i + 1) begin
    assign micro_mask_right[i] = micro_mask_left[BWIDTH-1-i];
  end
endgenerate

assign micro_mask_mxd = left_i ? micro_mask_left : micro_mask_right;


logic [$clog2(REG_WIDTH/BWIDTH)-1:0] macro_mask_apply_cyc;
logic [$clog2(REG_WIDTH/BWIDTH)-1:0] macro_repl_apply_cyc;
logic macro_repl_apply;


assign shamt_mxd_masks = instr_ld_i ? {ls_b_i|ls_h_i, ls_b_i, 3'b0} : shamt_i;


assign macro_mask_apply_cyc = left_i      ? macro_steps_ld_right :
                              instr_ld_i  ? (REG_WIDTH/BWIDTH) - 'd1 - ({ls_b_i|ls_h_i, ls_b_i, 3'b0} >> $clog2(BWIDTH)) :
                                             macro_steps_ld_left - 'd1;

assign macro_repl_apply_cyc = macro_mask_apply_cyc;

assign macro_repl_apply = left_i ? (icyc_i <= macro_repl_apply_cyc) : (icyc_i > macro_repl_apply_cyc);


assign repl_cap       = (icyc_i == macro_repl_apply_cyc);
assign micro_cap_mask = (arith_i<<(BWIDTH-1)) >> (shamt_mxd_masks & (BWIDTH-1));
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

assign reg_n  =  ld_par_i ? {{BWIDTH{1'bx}}, pdin_i}  :
                            {ser_i, reg_r[REG_WIDTH+BWIDTH-1:BWIDTH]};


// stop shifting when store data is in the right position
// TODO: merge this with macro steps, as those are not required when storing

logic [$clog2(REG_WIDTH/BWIDTH):0] hlt_reg_after;
logic hlt_reg;

assign hlt_reg_after =  (instr_st_i & ls_b_i)                 ? ((32-8*adr_lsbs_i)/BWIDTH)-'b1  :
                        (instr_st_i & ls_h_i & adr_lsbs_i[1]) ? (16/BWIDTH)-'b1                 :
                                                                '1;

assign hlt_reg = (icyc_i > hlt_reg_after);  // todo: replace with & reduction?


always_ff @(posedge clk_i) begin
  //
  if (~hlt_reg & (~cyc_wt_i | ld_par_i | cyc_rd_i | (~cyc_rd_i & ~cyc_wt_i & ~cyc_shft_i))) begin
    reg_r <= reg_n;
  end
end

// --- output ---

//
generate
if (CONF != "MIN")
  assign misalngd_o = ((|adr_lsbs_i) & ls_w_i) | (adr_lsbs_i[0] & ls_h_i);
else
`ifndef RISCV_FORMAL
  assign misalngd_o = 'b0;
`else
// Generate for framework, because the ls masks are not restricted to
// aligned accesses otherwise
  assign misalngd_o = ((|adr_lsbs_i) & ls_w_i) | (adr_lsbs_i[0] & ls_h_i);
`endif
endgenerate

assign shft_tap_pos = left_i ? (BWIDTH - (shamt_mxd_masks & (BWIDTH-1))) : (shamt_mxd_masks & (BWIDTH-1));

assign ser    =  cyc_rd_i ? reg_r[shft_tap_pos +: BWIDTH] : reg_r[BWIDTH +: BWIDTH]; //

// opt
assign ser_o =  cyc_shft_i                  ? reg_r[BWIDTH-1:0]                                           :
                (macro_mask_apply_cyc == icyc_i) ? (ser & ~micro_mask_mxd) | ({BWIDTH{repl}} & micro_mask_mxd) :
                 macro_repl_apply ? {BWIDTH{repl}}                                              :
                                              ser;

assign ser_pc_o = reg_r[BWIDTH +: BWIDTH];

assign pdout_o  = reg_r[BWIDTH +: 32];


/* verilator lint_on WIDTHEXPAND */
endmodule

