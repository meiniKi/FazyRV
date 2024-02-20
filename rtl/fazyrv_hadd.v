// Copyright (c) 2023 Meinhard Kissich
// -----------------------------------------------------------------------------
// File  :  fazyrv_hadd.v
// Usage :  Hald adder.
//
// Ports
//  - a_i       Input a.
//  - b_i       Input b.
//  - y_o       Sum.
//  - c_o       Carry out.
// -----------------------------------------------------------------------------
//     / \       Initial version for evaluating scalability.       / \
//    / | \             _Not_ recommended for use.                / | \
//   /  .  \   Please use the version in `main` branch instead.  /  .  \
// -----------------------------------------------------------------------------

module fazyrv_hadd
(
  input  wire a_i,
  input  wire b_i,
  output wire y_o,
  output wire c_o
);

assign y_o = a_i ^ b_i;
assign c_o = a_i & b_i;

endmodule

