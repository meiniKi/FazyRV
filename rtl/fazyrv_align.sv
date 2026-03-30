// Copyright (c) 2025 - 2026 Meinhard Kissich
// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
// File  :  fazyrv_align.sv
// Usage :  Alignes memory accesses at a 2-byte boundary
//          to word-aligned accesses.
//
// Param
//  - CHUNKSIZE     Data path width of the core. Thus, the width of the
//                  input vectors and result.
//
// Ports
//  - clk_i         Clock input, sensitive to rising edge.
//  - rst_in        Reset, low active.
//
//  - wb_core_stb_i Wishbone interface to core
//  - wb_core_adr_i   accesses either 2-byte or 4-byte aligned.
//  - wb_core_dat_o
//  - wb_core_ack_o
//
//  - wb_mem_stb_o Wishbone interface to memory
//  - wb_mem_adr_o    all accesses aligned to 4-byte boundary.
//  - wb_mem_dat_i
//  - wb_mem_ack_i
// -----------------------------------------------------------------------------

module fazyrv_align (
  input  logic          clk_i,
  input  logic          rst_in,

  input  logic          wb_core_stb_i,
  input  logic [31:0]   wb_core_adr_i,
  output logic [31:0]   wb_core_dat_o,
  output logic          wb_core_ack_o,

  output logic          wb_mem_stb_o,
  output logic [31:0]   wb_mem_adr_o,
  input  logic [31:0]   wb_mem_dat_i,
  input  logic          wb_mem_ack_i
);

logic is_misaligned;
logic active_r, active_n;
//logic mux_r, mux_n;

logic [15:0] hword_r, hword_n;

assign is_misaligned = wb_core_adr_i[1];

assign wb_mem_stb_o = wb_core_stb_i;

assign wb_mem_adr_o = active_r ? {wb_core_adr_i[31:2]+29'b1, 2'b00} : {wb_core_adr_i[31:2], 2'b00};

// No need to keep stable for longer
//assign wb_core_dat_o = mux_r ? {wb_mem_dat_i[15:0], hword_r} : wb_mem_dat_i;

assign wb_core_dat_o = is_misaligned ? {wb_mem_dat_i[15:0], hword_r} : wb_mem_dat_i;

assign wb_core_ack_o = wb_mem_ack_i & (~is_misaligned | active_r);

// wb_core_stb_i is included for safety, as multiplexed bus may ack back
// to any controller.
//
assign active_n = (wb_core_stb_i & wb_mem_ack_i) ?  is_misaligned & ~active_r : 
                                                    active_r;

assign hword_n = (wb_core_stb_i & wb_mem_ack_i & ~active_r) ? wb_mem_dat_i[31:16] : hword_r;

//assign mux_n = wb_core_stb_i ? is_misaligned : mux_r;

always_ff @(posedge clk_i) begin
  if (~rst_in) begin
    active_r <= 1'b0;
  end else begin
    active_r <= active_n;
  end

  //mux_r   <= mux_n;
  hword_r <= hword_n;
end

endmodule
