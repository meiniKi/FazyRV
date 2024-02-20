// Copyright (c) 2023 Meinhard Kissich
// -----------------------------------------------------------------------------
// File  :  fazyrv_shftreg.sv
// Usage :  Shiftable register used to implement the regfile with distr. memory.
// Param
//  - BWIDTH      Data path width of the core.
//
// Ports
//  - clk_i       Clock input, sensitive to rising edge.
//  - shft_i      Shift to next chunk.
//  - dat_i       Input data chunk.
//  - dat_o       Ouput data chunk.
//
//  - dbg_o       DEBUG only, parallel register data.
// -----------------------------------------------------------------------------
//     / \       Initial version for evaluating scalability.       / \
//    / | \             _Not_ recommended for use.                / | \
//   /  .  \   Please use the version in `main` branch instead.  /  .  \
// -----------------------------------------------------------------------------

module fazyrv_shftreg #( parameter BWIDTH=1 )
(
  input  logic              clk_i,
  input  logic              shft_i,
  input  logic [BWIDTH-1:0] dat_i,
  output logic [BWIDTH-1:0] dat_o
`ifdef RISCV_FORMAL
  ,
  output logic [31:0]       dbg_o
`endif
);

logic [31:0] reg_r;

assign dat_o = reg_r[BWIDTH-1:0];

always_ff @(posedge clk_i) begin
  if (shft_i) begin
    reg_r <= {dat_i, reg_r[31:BWIDTH]};
  end
end

`ifdef RISCV_FORMAL
assign dbg_o = reg_r;
`endif

endmodule

