// Copyright (c) 2023 - 2024 Meinhard Kissich
// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
// File  :  fazyrv_ram_sp.v
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
//  - raddr_i     Read address.
//  - wdata_i     Write data.
//  - rdata_o     Read data.
// -----------------------------------------------------------------------------

module fazyrv_ram_sp #( parameter REGW=32, parameter ADRW=5, parameter DEPTH=32 ) (
  input  logic            clk_i,
  input  logic            we_i,
  input  logic [ADRW-1:0] waddr_i,
  input  logic [ADRW-1:0] raddr_i,
  input  logic [REGW-1:0] wdata_i,
  output logic [REGW-1:0] rdata_o
);

logic [31:0] ram_r [0:DEPTH-1];

always_ff @(posedge clk_i) begin
  if (~we_i) begin
    rdata_o <= ram_r[raddr_i];
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

// --- RiscV Formal ---

`ifdef RISCV_FORMAL
initial begin
  for (i = 0; i < DEPTH; i = i + 1) begin
    ram_r[i] = '0;
  end
end
`endif


endmodule

