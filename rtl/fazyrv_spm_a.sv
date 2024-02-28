// Copyright (c) 2023 - 2024 Meinhard Kissich
// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
// File  :  fazyrv_spm_a.v
// Usage :  Scratchpad memory for addresses.
//
// Param
//  - CHUNKSIZE   Data path width of the core.
//
// Ports
//  - clk_i       Clock input, sensitive to rising edge.
//  - shft_i      Shift register, move to the next chunk.
//  - ser_i       Serial input data chunk.
//  - par_o       Parallel output of register content.
// -----------------------------------------------------------------------------


module fazyrv_spm_a #( parameter CHUNKSIZE=2 )
(
  input  logic                  clk_i,
  input  logic                  shft_i,
  input  logic [CHUNKSIZE-1:0]  ser_i,
  output logic [31:0]           par_o
);

logic [31:0] reg_r;

assign par_o = reg_r;

always_ff @(posedge clk_i) begin
  if (shft_i) begin
    reg_r <= {ser_i, reg_r[31:CHUNKSIZE]};
  end
end

endmodule

