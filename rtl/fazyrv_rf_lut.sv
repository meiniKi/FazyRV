// Copyright (c) 2023 - 2024 Meinhard Kissich
// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
// File  :  fazyrv_rf_lut.sv
// Usage :  Regfile implemented with logic.
//
// Param
//  - CHUNKSIZE   Data path width of the core.
//
// Ports
//  - clk_i       Clock input, sensitive to rising edge.
//  - rst_in      Reset, low active.
//  - shft_i      Shift data to next chunk.
//  - ram_wstb_i  Unused.
//  - ram_rstb_i  Unused.
//
//  - rs1_i       Register address r1.
//  - rs2_i       Register address r2.
//  - ra_o        Output data part of r1 address.
//  - rb_o        Output data part of r2 address.
//
//  - rd_i        Register address r2.
//  - res_i       Input data part for rd.
//  - we_i        Write enable.
//
//  - dbg_res_o   Optional: debug result output
// -----------------------------------------------------------------------------


module fazyrv_rf_lut #( parameter CHUNKSIZE=2 )
(
  input  logic              clk_i,
  input  logic              rst_in,
  input  logic              shft_i,
  input  logic              ram_wstb_i,
  input  logic              ram_rstb_i,

  // read interface
  input  logic [4:0]            rs1_i,
  input  logic [4:0]            rs2_i,
  output logic [CHUNKSIZE-1:0]  ra_o,
  output logic [CHUNKSIZE-1:0]  rb_o,

  // write interface
  input  logic [4:0]            rd_i,
  input  logic [CHUNKSIZE-1:0]  res_i,
  input  logic                  we_i

`ifdef RISCV_FORMAL
  ,
  output logic [31:0]       dbg_res_o
`endif
);

// Note: all regs shifted, may be optimized for energy
//       by only shifting rs1, rs2, and rd
// r0 will be optimized by the tools

logic [CHUNKSIZE-1:0] rdat [32];
logic [31:0]          we;

assign ra_o   = rdat[rs1_i];
assign rb_o   = rdat[rs2_i];

`ifdef RISCV_FORMAL
  logic [31:0] dbg [32];
  
  assign we         = {31'b0, we_i&rst_in} << rd_i;
  assign dbg[0]     = 'b0;
  assign dbg_res_o  = dbg[rd_i];
`else
  assign we = {31'b0, we_i} << rd_i;
`endif


generate
  genvar i;
  assign rdat[0] = 32'b0;
  for (i=1; i<32; i=i+1) begin
    logic [CHUNKSIZE-1:0] din;
    logic [CHUNKSIZE-1:0] dout;
    assign din      = we[i] ? res_i : dout;
    assign rdat[i]  = dout;

    fazyrv_shftreg #( .CHUNKSIZE(CHUNKSIZE) ) i_reg (
      .clk_i  ( clk_i   ),
      .shft_i ( shft_i  ),
      .dat_i  ( din     ),
      .dat_o  ( dout    )
`ifdef RISCV_FORMAL
      ,
      .dbg_o  ( dbg[i]  )
`endif
    );
  end
endgenerate


// ---- DEBUG -----

`ifdef DEBUG_SIM

(* keep *) logic [31:0] r1;
(* keep *) logic [31:0] r2;
(* keep *) logic [31:0] r3;
(* keep *) logic [31:0] r4;
(* keep *) logic [31:0] r5;
(* keep *) logic [31:0] r6;
(* keep *) logic [31:0] r7;
(* keep *) logic [31:0] r8;
(* keep *) logic [31:0] r9;
(* keep *) logic [31:0] r10;
(* keep *) logic [31:0] r11;
(* keep *) logic [31:0] r12;
(* keep *) logic [31:0] r13;
(* keep *) logic [31:0] r14;
(* keep *) logic [31:0] r15;
(* keep *) logic [31:0] r16;
(* keep *) logic [31:0] r17;
(* keep *) logic [31:0] r18;
(* keep *) logic [31:0] r19;
(* keep *) logic [31:0] r20;
(* keep *) logic [31:0] r21;
(* keep *) logic [31:0] r22;
(* keep *) logic [31:0] r23;
(* keep *) logic [31:0] r24;
(* keep *) logic [31:0] r25;
(* keep *) logic [31:0] r26;
(* keep *) logic [31:0] r27;
(* keep *) logic [31:0] r28;
(* keep *) logic [31:0] r29;
(* keep *) logic [31:0] r30;
(* keep *) logic [31:0] r31;

assign r1   = regs_a[1].i_reg.reg_r;
assign r2   = regs_a[2].i_reg.reg_r;
assign r3   = regs_a[3].i_reg.reg_r;
assign r4   = regs_a[4].i_reg.reg_r;
assign r5   = regs_a[5].i_reg.reg_r;
assign r6   = regs_a[6].i_reg.reg_r;
assign r7   = regs_a[7].i_reg.reg_r;
assign r8   = regs_a[8].i_reg.reg_r;
assign r9   = regs_a[9].i_reg.reg_r;
assign r10  = regs_a[10].i_reg.reg_r;
assign r11  = regs_a[11].i_reg.reg_r;
assign r12  = regs_a[12].i_reg.reg_r;
assign r13  = regs_a[13].i_reg.reg_r;
assign r14  = regs_a[14].i_reg.reg_r;
assign r15  = regs_a[15].i_reg.reg_r;
assign r16  = regs_a[16].i_reg.reg_r;
assign r17  = regs_a[17].i_reg.reg_r;
assign r18  = regs_a[18].i_reg.reg_r;
assign r19  = regs_a[19].i_reg.reg_r;
assign r20  = regs_a[20].i_reg.reg_r;
assign r21  = regs_a[21].i_reg.reg_r;
assign r22  = regs_a[22].i_reg.reg_r;
assign r23  = regs_a[23].i_reg.reg_r;
assign r24  = regs_a[24].i_reg.reg_r;
assign r25  = regs_a[25].i_reg.reg_r;
assign r26  = regs_a[26].i_reg.reg_r;
assign r27  = regs_a[27].i_reg.reg_r;
assign r28  = regs_a[28].i_reg.reg_r;
assign r29  = regs_a[29].i_reg.reg_r;
assign r30  = regs_a[30].i_reg.reg_r;
assign r31  = regs_a[31].i_reg.reg_r;

`endif

endmodule

