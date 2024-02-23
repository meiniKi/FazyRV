// Copyright (c) 2023 - 2024 Meinhard Kissich
// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
// File  :  fazyrv_alu.sv
// Usage :  Serial ALU as used in the FazyRV core.
//
// Param
//  - CHUNKSIZE     Data path width of the core. Thus, the width of the
//                  input vectors and result.
//
// Ports
//  - clk_i         Clock input, sensitive to rising edge.
//  - lsb_i         High iff LSB of data is processed at next clk.
//  - msb_i         High iff MSB of data is processed at next clk.
//
//  - rs_a_i        ALU operand a.
//  - rs_b_i        ALU operand b.
//  - res_o         ALU result, e.g., arithmetic or logical.
//  - cmp_o         ALU comparator result.
//
//  - sel_arith_i   Select a logical op (0) or an arithmetic op (1).
//  - en_a_i        Enable input a, otherwise set to zero, e.g., for
//                  pass through (shift).
//  - op_sub_i      Perform subtraction (1) or addition (0).
//  - op_xor_i      Perform xor, all 0 is or.
//  - op_and_i      Perform and operation.
//
//  - cmp_keep_i    If high, then cmp registers is _not_ overwritten.
//  - cmp_signd_i   Perform a signed comparison.
//  - cmp_eq_i      Check if inputs are equal (1), otherwise lt (0).
// -----------------------------------------------------------------------------

module fazyrv_alu #( parameter CHUNKSIZE=2 )
(
  input  logic                  clk_i,
  input  logic                  lsb_i,
  input  logic                  msb_i,

  input  logic [CHUNKSIZE-1:0]  rs_a_i,
  input  logic [CHUNKSIZE-1:0]  rs_b_i,
  output logic [CHUNKSIZE-1:0]  res_o,
  output logic                  cmp_o,

  input  logic                  sel_arith_i,
  input  logic                  en_a_i,
  input  logic                  op_sub_i,
  input  logic                  op_xor_i,
  input  logic                  op_and_i,

  input  logic                  cmp_keep_i,
  input  logic                  cmp_signd_i,
  input  logic                  cmp_eq_i
);

logic [CHUNKSIZE-1:0] rs_a;
logic [CHUNKSIZE-1:0] rs_b;

logic [CHUNKSIZE-1:0] add_y;
logic [CHUNKSIZE:0]   carry;

logic [CHUNKSIZE-1:0] xor_y;
logic [CHUNKSIZE-1:0] and_y;

reg carry_r;
reg cmp_r;

assign rs_a = {CHUNKSIZE{en_a_i}} & rs_a_i;
assign rs_b = rs_b_i ^ {CHUNKSIZE{op_sub_i}};

// ---------------------------------
// ADD, SUB, AND, XOR by full adder
// ---------------------------------

genvar i;
generate
  for (i=0; i<CHUNKSIZE; i=i+1) begin
    fazyrv_fadd i_fazyrv_fadd_x (
      .a_i      ( rs_a[i]     ),
      .b_i      ( rs_b[i]     ),
      .c_i      ( carry[i]    ),
      .y_o      ( add_y[i]    ),
      .c_o      ( carry[i+1]  ),
      .axorb_o  ( xor_y[i]    ),
      .aandb_o  ( and_y[i]    )
    );
  end
endgenerate

// --- Carry ---

always_ff @(posedge clk_i) begin
  carry_r <= carry[$size(carry)-1];
end

assign carry[0] = lsb_i ? op_sub_i : carry_r;

// -- Compares --

logic cmp_n;
logic lo;
logic gr;

always_ff @(posedge clk_i) begin
  cmp_r <= cmp_n;
end

fazyrv_cmp #( .CHUNKSIZE(CHUNKSIZE) ) i_favyrv_cmp
(
  .a_i        ( rs_a                ),
  .b_i        ( rs_b                ),
  .inv_msb_i  ( msb_i & cmp_signd_i ),
  .lo_o       ( lo                  ),
  .gr_o       ( gr                  )
);


/*
assign cmp_n =  cmp_keep_i  ? cmp_r :
                cmp_eq_i    ? ((cmp_r|lsb_i) & (rs_a == rs_b)) :
                lo          ? 1'b1 :
                gr          ? 1'b0 :
                lsb_i       ? 1'b0 : cmp_r;
*/

// Overlapp warning
//always_comb begin
//  casez ({cmp_keep_i, cmp_eq_i, lo, gr, lsb_i})
//    5'b01???:  cmp_n = ((cmp_r|lsb_i) & ~lo & ~gr);
//    5'b0?1??:  cmp_n = 1'b1;
//    5'b0??1?:  cmp_n = 1'b0;
//    5'b0???1:  cmp_n = 1'b0;
//    default: cmp_n = cmp_r;
//  endcase
//end

//
// Version below is identical but smaller
//
always_comb begin
  casez ({cmp_keep_i, cmp_eq_i, lo, gr, lsb_i})
    5'b01???:  cmp_n = ((cmp_r|lsb_i) & ~lo & ~gr);
    5'b001??:  cmp_n = 1'b1;
    5'b0001?:  cmp_n = 1'b0;
    5'b00001:  cmp_n = 1'b0;
    default:   cmp_n = cmp_r;
  endcase
end

// --- Output MUX --

assign cmp_o = cmp_n;

assign res_o = ( {CHUNKSIZE{~sel_arith_i}}  &
                ( ({CHUNKSIZE{op_xor_i}} & xor_y) |
                  ({CHUNKSIZE{op_and_i}} & and_y) |
                  {CHUNKSIZE{(~(op_xor_i | op_and_i))}} & (rs_a | rs_b) ) |
              ({CHUNKSIZE{sel_arith_i}} & add_y));

endmodule

