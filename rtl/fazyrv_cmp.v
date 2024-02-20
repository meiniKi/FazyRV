// Copyright (c) 2023 Meinhard Kissich
// -----------------------------------------------------------------------------
// File  :  fazyrv_cmp.v
// Usage :  Compare two vectors a_i and b_i and output whether a_i is smaller
//          (lo_o) or greater (gr_o). One additional input bit (inv_msb_i)
//          inverts the MSB of both vectors when high.
//
// Param
//  - BWIDTH    Data path width of the core. Thus, the width of the 
//              input vectors.
// Ports
//  - a_i       Input vector a.
//  - b_i       Input vector b.
//  - inv_msb_i If high, inverse the MSB of both vectors.
//  - lo_o      High iff a_i is lower than b_i.
//  - gr_o      High iff a_i is greater than b_i.
// -----------------------------------------------------------------------------
//     / \       Initial version for evaluating scalability.       / \
//    / | \             _Not_ recommended for use.                / | \
//   /  .  \   Please use the version in `main` branch instead.  /  .  \
// -----------------------------------------------------------------------------

module fazyrv_cmp #( parameter BWIDTH=2 )
(
  input  wire [BWIDTH-1:0] a_i,
  input  wire [BWIDTH-1:0] b_i,
  input  wire inv_msb_i,
  output wire lo_o,
  output wire gr_o
);

// TODO: optimize, I guess this does not synth optimally
//

wire [BWIDTH-1:0] a_mod;
wire [BWIDTH-1:0] b_mod;

//
//
//assign a_mod = inv_msb_i ? {~a_i[BWIDTH-1], a_i[0 +: (BWIDTH-1)]} : a_i;
//assign b_mod = inv_msb_i ? {~b_i[BWIDTH-1], b_i[0 +: (BWIDTH-1)]} : b_i;

generate
  if (BWIDTH == 1) begin
    assign a_mod = inv_msb_i ? ~a_i : a_i;
    assign b_mod = inv_msb_i ? ~b_i : b_i;
  end else begin
    assign a_mod = inv_msb_i ? {~a_i[BWIDTH-1], a_i[0 +: (BWIDTH-1)]} : a_i;
    assign b_mod = inv_msb_i ? {~b_i[BWIDTH-1], b_i[0 +: (BWIDTH-1)]} : b_i;
  end
endgenerate

assign lo_o = a_mod < b_mod;
assign gr_o = a_mod > b_mod;

endmodule

