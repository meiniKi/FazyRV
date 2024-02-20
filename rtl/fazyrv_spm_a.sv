// Copyright (c) 2023 Meinhard Kissich
// -----------------------------------------------------------------------------
// File  :  fazyrv_spm_a.sv
// Usage :  Scratchpad memory for addresses.
//
// Param
//  - BWIDTH      Data path width of the core.
//
// Ports
//  - clk_i       Clock input, sensitive to rising edge.
//  - shft_i      Shift register, move to the next chunk.
//  - ser_i       Serial input data chunk.
//  - par_o       Parallel output of register content.
// -----------------------------------------------------------------------------
//     / \       Initial version for evaluating scalability.       / \
//    / | \             _Not_ recommended for use.                / | \
//   /  .  \   Please use the version in `main` branch instead.  /  .  \
// -----------------------------------------------------------------------------

module fazyrv_spm_a #( parameter BWIDTH=8 )
(
  input  logic              clk_i,
  input  logic              shft_i,
  input  logic [BWIDTH-1:0] ser_i,
  output logic [31:0]       par_o
);

logic [31:0] reg_r;

assign par_o = reg_r;

always_ff @(posedge clk_i) begin
  if (shft_i) begin
    reg_r <= {ser_i, reg_r[31:BWIDTH]};
  end
end

endmodule

