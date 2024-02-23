// Copyright (c) 2023 - 2024 Meinhard Kissich
// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
// File  :  fazyrv_pc.sv
// Usage :  Programm Counter register.
//
// Param
//  - CHUNKSIZE     Data path width of the core.
//  - BOOTADR       Initial value of the PC.
//
// Ports
//  - clk_i         Clock input, sensitive to rising edge.
//  - rst_in        Reset, low active.
//  - inc_i         Strobe to increment PC in the subsequent cylce.
//  - shift_i       Shift PC register.
//  - din_i         New input data part when PC is shifted.
//  - pc_ser_o      Serial output part of PC register.
//  - pc_ser_inc_o  Serial output of incremented part of PC register.
//  - pc_o          Parallel output of PC.
// -----------------------------------------------------------------------------

module fazyrv_pc #( parameter CHUNKSIZE=2, parameter BOOTADR=32'hFFFF )
(
  input  logic                  clk_i,
  input  logic                  rst_in,
  input  logic                  inc_i,
  input  logic                  shift_i,
  input  logic [CHUNKSIZE-1:0]  din_i,
  output logic [CHUNKSIZE-1:0]  pc_ser_o,
  output logic [CHUNKSIZE-1:0]  pc_ser_inc_o,
  output logic [31:0]           pc_o
);

// restrictions: pc currenctly must be %4
// otherwise opt with carry does not work

logic [31:0] pc_r, pc_n;
logic [CHUNKSIZE-1:0]  pc_inc;

assign pc_o         = pc_r;
assign pc_ser_o     = pc_r[CHUNKSIZE-1:0];
assign pc_ser_inc_o = pc_inc;


// --- increment ---

localparam CARRY_REG_WIDTH  = (CHUNKSIZE == 1) ? 2 : 1;
localparam ADD_VEC_WIDTH    = (CHUNKSIZE < 3)  ? 3 : CHUNKSIZE;

logic [CARRY_REG_WIDTH-1:0] carry_r;
logic [ADD_VEC_WIDTH-1:0]   add_vec;
logic [CHUNKSIZE:0]         carry_vec;


logic [CARRY_REG_WIDTH-1:0] add_rem;
logic carry_rem;
generate
/* svlint off style_keyword_1or2space */
/* svlint off style_keyword_construct */
/* svlint off style_keyword_1space */
  if      (CHUNKSIZE == 1)  assign add_rem = add_vec[2:1];
  else if (CHUNKSIZE == 2)  assign add_rem = add_vec[2];
  else                      assign add_rem = 1'b0;

  if      (CHUNKSIZE == 1)  assign carry_rem = carry_r[1];
  else                      assign carry_rem = 1'b0;
/* svlint on style_keyword_1or2space */
/* svlint on style_keyword_construct */
/* svlint off style_keyword_1space */
endgenerate

always_ff @(posedge clk_i) begin
  if (~rst_in) begin
    carry_r <= 'b0;
  end
    carry_r <= add_rem |
            {{CARRY_REG_WIDTH-1{1'b0}}, (carry_rem | carry_vec[CHUNKSIZE])};
end

genvar i;
generate
  for (i=0; i<CHUNKSIZE; i=i+1) begin
    logic b;
    if (i < ADD_VEC_WIDTH) begin
      assign b = (add_vec[i]|carry_vec[i]);
    end else begin
      assign b = carry_vec[i];
    end
    //             a,     b,   y,         c
    fazyrv_hadd i_hadd (pc_r[i], b, pc_inc[i], carry_vec[i+1]);
  end
endgenerate

assign add_vec = {{(ADD_VEC_WIDTH-3){1'b0}}, inc_i, 2'b00};

assign carry_vec[0] = carry_r[0];

assign pc_n = shift_i ? {din_i, pc_r[31:CHUNKSIZE]} : pc_r;

always_ff @(posedge clk_i) begin
  if (~rst_in) begin
    pc_r <= BOOTADR;
  end else begin
    pc_r <= pc_n;
  end
end


endmodule

