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

// Insert sky130 buffers manually to achieve a higher
// placement density. Inspired by MichaelBell/tinyQV
// www.github.com/MichaelBell/tinyQV/blob/69ce898bf1122e91a3114f3f0fe8e4bdf242f7f0/cpu/register.v#L58
//

logic [31-CHUNKSIZE:0] reg_dlyd;
`ifdef SKY130
  sky130_fd_sc_hd__dlygate4sd3_1 i_buf[31-CHUNKSIZE:0] ( .X(reg_dlyd), .A(reg_r[31:CHUNKSIZE]) );
`else
  buf #1 i_buf[31:CHUNKSIZE] (reg_dlyd, reg_r[31:CHUNKSIZE]);
`endif

assign dat_o = reg_r[CHUNKSIZE-1:0];

always_ff @(posedge clk_i) begin
  if (shft_i) begin
    reg_r <= {dat_i, reg_dlyd};
  end
end

`ifdef RISCV_FORMAL
assign dbg_o = reg_r;
`endif

endmodule

