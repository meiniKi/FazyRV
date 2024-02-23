// Copyright (c) 2023 - 2024 Meinhard Kissich
// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
// File  :  fazyrv_shftreg.sv
// Usage :  Shiftable register used to implement the regfile with distr. memory.
//
// Param
//  - CHUNKSIZE   Data path width of the core.
//
// Ports
//  - clk_i       Clock input, sensitive to rising edge.
//  - shft_i      Shift to next chunk.
//  - dat_i       Input data chunk.
//  - dat_o       Ouput data chunk.
//
//  - dbg_o       DEBUG only, parallel register data.
// -----------------------------------------------------------------------------


module fazyrv_shftreg #( parameter CHUNKSIZE=2 )
(
  input  logic                  clk_i,
  input  logic                  shft_i,
  input  logic [CHUNKSIZE-1:0]  dat_i,
  output logic [CHUNKSIZE-1:0]  dat_o
`ifdef RISCV_FORMAL
  ,
  output logic [31:0]           dbg_o
`endif
);

`ifdef RISCV_FORMAL
logic [31:0] reg_r = 'b0;
`else
logic [31:0] reg_r;
`endif

assign dat_o = reg_r[CHUNKSIZE-1:0];

always_ff @(posedge clk_i) begin
  if (shft_i) begin
    reg_r <= {dat_i, reg_r[31:CHUNKSIZE]};
  end
end

`ifdef RISCV_FORMAL
assign dbg_o = reg_r;
`endif

endmodule

