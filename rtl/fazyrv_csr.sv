// Copyright (c) 2023 - 2024 Meinhard Kissich
// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
// File  :  fazyrv_csr.v
// Usage :  Implements CSRs. WIP!
//          Decision on deviations from the specification to be done.
//
// Param
//  - CONF          Features of core.
//  - REGW          Width of the registers in bits.
//
// Ports
//  - clk_i         Clock input, sensitive to rising edge.
//  - rst_in        Reset, low active.
//
//  - csr_wstb_i    Strobe access.
//  - csr_rs_i      Address.
//  - csr_hpmtc_i   Is hpmtc address.
//  - csr_info_new_insn_i Inform about a new instruction.
//
//  - csr_rs1_en_i  Read into ra enable.
//  - csr_rs2_en_i  Read into rb enable.
//
//  - rdata_ab_o    Ra, or shared ra rb in case of single-port ram.
//  - rdata_b_o     Rb, or ignored in case of single-port ram.
//  - wdata_i       Write data.
//
//  - trap_i        Inform about trap.
//  - mret_i        Inform about return from trap.
//  - mcause30_i    Bits 3 and 0 of mcause.
//  - mcause_int_i  Trap is interrupt (high), or exception (low).
//  - mtie_o        Interrupt enable.
// -----------------------------------------------------------------------------


module fazyrv_csr #(
  parameter CONF  = "MIN",
  parameter REGW  = 32
) (
  input  logic              clk_i,
  input  logic              rst_in,

  input  logic              csr_wstb_i, // includes we, ~ram_rd_en
  input  logic [4:0]        csr_rs_i,
  input  logic              csr_hpmtc_i,
  input  logic              csr_info_new_insn_i,

  input  logic              csr_rs1_en_i,
  input  logic              csr_rs2_en_i,

  output logic [REGW-1:0]   rdata_ab_o, // most bits shall be opt away
  output logic [REGW-1:0]   rdata_b_o,
  input  logic [REGW-1:0]   wdata_i,

  input  logic              trap_i,
  input  logic              mret_i,
  input  logic [1:0]        mcause30_i,
  input  logic              mcause_int_i,
  output logic              mtie_o
);

logic [63:0]  cycle_r   = 64'bx;
logic [63:0]  instret_r = 64'bx;

logic mstatus_mie_r;
logic mstatus_mpie_r;
logic mie_mtie_r;
logic mcause_int_r;
logic mcause_3_r;
logic mcause_0_r;

// [7]  -> 1==h, 0==l
// [11] -> 1==time/cyc, 0==other csr
// cycle and time read back the same value
// cycle    0xC00    cycleh 0xC80 -> ra_r (low), rb_r (high)
// time     0xC01    timeh  0xC81 -> ra_r (low), rb_r (high)
// instret  0xC02    ...
// 1100_0000_0000

//localparam ADR_MSTATUS       // 0x300, 0b00 000    bits: 7, 3        ff
//localparam ADR_MIP           // 0x344, 0b01 100    bits: 7           ff
//localparam ADR_MCAUSE        // 0x342  0b00 010    bits:    3, 1, 0  ff
//localparam ADR_MIE           // 0x304, 0b00 100    bits: 7           ff
//localparam ADR_TIME          // 0xC01, 0b10 001
//localparam ADR_INTRET        // 0xC02, 0b10 010
//localparam ADR_MEPC    = 33; // 0x341, 0b00 001    bits: all     ram
//localparam ADR_MTVAL   = 35; // 0x343, 0b00 011    bits: all     ram

//localparam ADR_MSCRATCH = 32 // 0x340, 0b00 000

// For the prove of concept, let us implement `instret` and `cycle` here.
// They will be moved into the sram and written during the cycle exec
// Deviation from spec: mcause not writable!

// TODO: for INT, set mie default enable and remove write and read logic
// TODO: reset not necessary for spec

// --- Write interface ---

always_ff @(posedge clk_i) begin
  if (~rst_in) begin
    mie_mtie_r                              <= 'b0;
    {mstatus_mpie_r, mstatus_mie_r}         <= 'b0;
    {mcause_int_r, mcause_3_r, mcause_0_r}  <= 'b0;
  end else begin

    // Write user
    if (csr_wstb_i & ~csr_hpmtc_i) begin
      casez (csr_rs_i[2:1])
        2'b10: begin
          mie_mtie_r      <= wdata_i[7];
        end
        2'b00: begin
          mstatus_mpie_r  <= wdata_i[7];
          mstatus_mie_r   <= wdata_i[3];
        end
        // MCAUSE writable? Deviation from spec
        //2'01: begin
        //
        //end
        // MPIE
        default:;
      endcase
    end

    // Modify through mret or trap
    if (mret_i) begin
      {mstatus_mpie_r, mstatus_mie_r} <= {1'b1, mstatus_mpie_r};
    end

    if (trap_i) begin
      {mstatus_mpie_r, mstatus_mie_r} <= {mstatus_mie_r, 1'b0};
      {mcause_3_r, mcause_0_r}        <= mcause30_i;
      mcause_int_r                    <= mcause_int_i;
    end
  end
end

assign mtie_o = mstatus_mie_r & mie_mtie_r;

// --- Read Interface ---

always_comb begin
  rdata_ab_o  = 'b0;
  rdata_b_o   = 'b0;

  if (csr_rs1_en_i & csr_hpmtc_i) begin
    if (csr_rs_i[1])
      rdata_ab_o = instret_r[31:0];
    else
      rdata_ab_o = cycle_r[31:0];
  end

  if (csr_rs2_en_i) begin
    casez ({csr_hpmtc_i, csr_rs_i[2:1]})
      3'b1?1:  rdata_b_o = instret_r[63:32];
      3'b010:  rdata_b_o = {24'b0, mie_mtie_r, 7'b0};
      3'b000:  rdata_b_o = {24'b0, mstatus_mpie_r, 3'b0, mstatus_mie_r, 3'b0};
      3'b0?1:  rdata_b_o = {mcause_int_r, 28'b0, mcause_3_r|mcause_int_r, mcause_int_r, mcause_0_r|mcause_int_r};
      default: rdata_b_o = cycle_r[63:32];
    endcase
  end
end


// --- CSR only (not available for INT) ---

generate
  if (CONF == "CSR") begin
    always_ff @(posedge clk_i) begin
      if (~rst_in) begin
        cycle_r   <= 64'b0;
        instret_r <= 64'b0;
      end else begin
        cycle_r   <= cycle_r + 64'b1;
        instret_r <= instret_r + {63'b0, csr_info_new_insn_i};
      end
    end
  end
endgenerate


endmodule

