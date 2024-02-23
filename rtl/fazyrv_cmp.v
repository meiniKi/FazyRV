// Copyright (c) 2023 - 2024 Meinhard Kissich
// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
// File  :  fazyrv_cmp.v
// Usage :  Compare two vectors a_i and b_i and output whether a_i is smaller
//          (lo_o) or greater (gr_o). One additional input bit (inv_msb_i)
//          inverts the MSB of both vectors when high.
//
// Param
//  - CHUNKSIZE Data path width of the core. Thus, the width of the
//              input vectors.
//
// Ports
//  - a_i       Input vector a.
//  - b_i       Input vector b.
//  - inv_msb_i If high, inverse the MSB of both vectors.
//  - lo_o      High iff a_i is lower than b_i.
//  - gr_o      High iff a_i is greater than b_i.
// -----------------------------------------------------------------------------

module fazyrv_cmp #( parameter CHUNKSIZE=2 )
(
  input  wire [CHUNKSIZE-1:0] a_i,
  input  wire [CHUNKSIZE-1:0] b_i,
  input  wire                 inv_msb_i,
  output wire                 lo_o,
  output wire                 gr_o
);

// TODO: optimize, I guess this does not synth optimally
//

wire [CHUNKSIZE-1:0] a_mod;
wire [CHUNKSIZE-1:0] b_mod;

// This gives a strange behavior for BWDITH==1 --> b does invert, a not
// TODO: check
//
//assign a_mod = inv_msb_i ? {~a_i[CHUNKSIZE-1], a_i[0 +: (CHUNKSIZE-1)]} : a_i;
//assign b_mod = inv_msb_i ? {~b_i[CHUNKSIZE-1], b_i[0 +: (CHUNKSIZE-1)]} : b_i;

generate
  if (CHUNKSIZE == 1) begin
    assign a_mod = inv_msb_i ? ~a_i : a_i;
    assign b_mod = inv_msb_i ? ~b_i : b_i;
  end else begin
    assign a_mod = inv_msb_i ? {~a_i[CHUNKSIZE-1], a_i[0 +: (CHUNKSIZE-1)]} : a_i;
    assign b_mod = inv_msb_i ? {~b_i[CHUNKSIZE-1], b_i[0 +: (CHUNKSIZE-1)]} : b_i;
  end
endgenerate

assign lo_o = a_mod < b_mod;
assign gr_o = a_mod > b_mod;

endmodule

