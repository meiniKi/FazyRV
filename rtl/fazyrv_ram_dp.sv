// Copyright (c) 2023 - 2024 Meinhard Kissich
// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
// File  :  fazyrv_ram_dp.sv
// Usage :  General purpose RAM used in FazyRV SoCs.
//
// Param
//  - REGW        Width of registers.
//  - ADRW        Width of address.
//  - DEPTH       Depth of memory.
//
// Ports
//  - clk_i       Clock input, sensitive to rising edge.
//  - we_i        Write enable.
//  - waddr_i     Write address.
//  - wdata_i     Write data.
//  - raddr_a_i   Read address port a.
//  - rdata_a_o   Read data port a.
//  - raddr_b_i   Read address port b.
//  - rdata_b_o   Read data port b.
// -----------------------------------------------------------------------------


module fazyrv_ram_dp #( parameter REGW=32, parameter ADRW=5, parameter DEPTH=32 ) (
  input  logic            clk_i,
  input  logic            we_i,
  input  logic [ADRW-1:0] waddr_i,
  input  logic [REGW-1:0] wdata_i,
  input  logic [ADRW-1:0] raddr_a_i,
  output logic [REGW-1:0] rdata_a_o,
  input  logic [ADRW-1:0] raddr_b_i,
  output logic [REGW-1:0] rdata_b_o
);

logic [31:0] ram_r [0:DEPTH-1];

always_ff @(posedge clk_i) begin
  if (~we_i) begin
    rdata_a_o <= ram_r[raddr_a_i];
    rdata_b_o <= ram_r[raddr_b_i];
  end else if (we_i) begin
    ram_r[waddr_i] <= wdata_i;
  end
end


int i;

// --- Sim ---

`ifdef SIM
initial begin
  for (i = 0; i < DEPTH; i = i + 1) begin
    ram_r[i] = '0;
  end
end
`endif

// --- RISCV Formal ---

`ifdef RISCV_FORMAL
initial begin
  for (i = 0; i < DEPTH; i = i + 1) begin
    ram_r[i] = '0;
  end
end
`endif


endmodule

