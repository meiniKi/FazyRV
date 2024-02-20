// Copyright (c) 2023 Meinhard Kissich
// -----------------------------------------------------------------------------
// File  :  fazyrv_pc.sv
// Usage :  Programm Counter register.
//
// Param
//  - BWIDTH        Data path width of the core.
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
//     / \       Initial version for evaluating scalability.       / \
//    / | \             _Not_ recommended for use.                / | \
//   /  .  \   Please use the version in `main` branch instead.  /  .  \
// -----------------------------------------------------------------------------

module fazyrv_pc #( parameter BWIDTH=8, parameter BOOT_ADDR=32'hFFFF )
(
  input  logic              clk_i,
  input  logic              rst_in,
  input  logic              inc_i,
  input  logic              shift_i,
  input  logic [BWIDTH-1:0] din_i,
  output logic [BWIDTH-1:0] pc_ser_o,
  output logic [BWIDTH-1:0] pc_ser_inc_o,
  output logic [31:0]       pc_o
);

// restrictions: pc currenctly must be %4
// otherwise opt with carry does not work

logic [31:0] pc_r, pc_n;
logic [BWIDTH-1:0]  pc_inc;

assign pc_o         = pc_r;
assign pc_ser_o     = pc_r[BWIDTH-1:0];
assign pc_ser_inc_o = pc_inc;


// --- increment ---

localparam CARRY_REG_WIDTH  = (BWIDTH == 1) ? 2 : 1;
localparam ADD_VEC_WIDTH    = (BWIDTH < 3)  ? 3 : BWIDTH;

logic [CARRY_REG_WIDTH-1:0] carry_r;
logic [ADD_VEC_WIDTH-1:0]   add_vec;
logic [BWIDTH:0]            carry_vec;


logic [CARRY_REG_WIDTH-1:0] add_rem;
logic carry_rem;
generate
/* svlint off style_keyword_1or2space */
/* svlint off style_keyword_construct */
/* svlint off style_keyword_1space */
  if      (BWIDTH == 1) assign add_rem = add_vec[2:1];
  else if (BWIDTH == 2) assign add_rem = add_vec[2];
  else                  assign add_rem = 1'b0;

  if      (BWIDTH == 1) assign carry_rem = carry_r[1];
  else                  assign carry_rem = 1'b0;
/* svlint on style_keyword_1or2space */
/* svlint on style_keyword_construct */
/* svlint off style_keyword_1space */
endgenerate

always_ff @(posedge clk_i) begin
  if (~rst_in) begin
    carry_r <= 'b0;
  end
    carry_r <= add_rem |
            {{CARRY_REG_WIDTH-1{1'b0}}, (carry_rem | carry_vec[BWIDTH])};
end

genvar i;
generate
  for (i=0; i<BWIDTH; i=i+1) begin
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

assign pc_n = shift_i ? {din_i, pc_r[31:BWIDTH]} : pc_r;

always_ff @(posedge clk_i) begin
  if (~rst_in) begin
    pc_r <= BOOT_ADDR;
  end else begin
    pc_r <= pc_n;
  end
end


endmodule

