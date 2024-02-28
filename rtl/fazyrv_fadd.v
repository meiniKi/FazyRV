// Copyright (c) 2023 - 2024 Meinhard Kissich
// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
// File  :  fazyrv_fadd.v
// Usage :  Full adder.
//
// Ports
//  - a_i       Input a.
//  - b_i       Input b.
//  - c_i       Carry in.
//  - y_o       Sum.
//  - c_o       Carry out.
//  - axorb_o   a xor b as side product.
//  - aandb_o   a and b as side product.
// -----------------------------------------------------------------------------


module fazyrv_fadd
(
  input  wire a_i,
  input  wire b_i,
  input  wire c_i,
  output wire y_o,
  output wire c_o,
  output wire axorb_o,
  output wire aandb_o
);

wire y1, c1, c2;

fazyrv_hadd i_hadd_a (a_i, b_i, y1,  c1);
fazyrv_hadd i_hadd_b (y1,  c_i, y_o, c2);

assign axorb_o = y1;
assign aandb_o = c1;
assign c_o = c1 | c2;

endmodule

