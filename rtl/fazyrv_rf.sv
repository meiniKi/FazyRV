// Copyright (c) 2023 Meinhard Kissich
// -----------------------------------------------------------------------------
// File  :  fazyrv_rf.sv
// Usage :  Regfile implemented with BRAM.
// Ports
//  - clk_i           Clock input, sensitive to rising edge.
//  - rst_in          Reset, low active.
//  - rf_shft_i       Shift data to next chunk.
//  - rf_wstb_i       Strobe to write data to BRAM.
//  - rf_rstb_i       Strobe to read either ra or rb (alternating if s.p. ram).
//  - rf_rs1_i        Register address of ra.
//  - rf_rs2_i        Register address of rb.
//  - rf_ra_o         Register ra chunk data.
//  - rf_rb_o         Register rb chunk data.
//  - rf_rd_i         Register address to write.
//  - rf_res_i        Chunk data to write.
//  - rf_we_i         Write enable.
//  - csr_adr_space_i Addressing CSR address space.
//  - csr_hpmtc_i     CSR is hpmtc.
//  - csr_6_i         Bit 6 of CSR address.
//
//  - csr_info_new_insn_i Inform about new instruction.
//  - trap_i          Entering trap.
//  - mret_i          Returning from trap.
//  - mcause30_i      Bits 3 and 0 of mcause.
//  - mcause_int_i    Trap is interrupt.
//  - mtie_o          Interrupt enable.
//  - ram_we_o        Write enable.
//  - ram_waddr_o     Write address.
//  - ram_wdata_o     Write data.
//  - ram_raddr_ab_o  Ra addr, or shared ra and rb addr if single port.
//  - ram_raddr_b_o   Rb addr, or ignored if single port.
//  - ram_rdata_ab_i  Ra, or shared ra and rb if single port. 
//  - ram_rdata_b_i   Rb, or ignored if single port.
//  - dbg_res_o       Optional: debug output.
// -----------------------------------------------------------------------------
//     / \       Initial version for evaluating scalability.       / \
//    / | \             _Not_ recommended for use.                / | \
//   /  .  \   Please use the version in `main` branch instead.  /  .  \
// -----------------------------------------------------------------------------

module fazyrv_rf #(
  parameter BWIDTH      = 1,
  parameter RF_TYPE     = "BRAM",
  parameter CONF        = "MIN",
  parameter ADR_WIDTH   = 5
) (
  input  logic              clk_i,
  input  logic              rst_in,

  input  logic              rf_shft_i,
  input  logic              rf_wstb_i,
  input  logic              rf_rstb_i,

  // rf interface
  input  logic [4:0]        rf_rs1_i,
  input  logic [4:0]        rf_rs2_i,
  output logic [BWIDTH-1:0] rf_ra_o,
  output logic [BWIDTH-1:0] rf_rb_o,
  input  logic [4:0]        rf_rd_i,
  input  logic [BWIDTH-1:0] rf_res_i,
  input  logic              rf_we_i,

  input  logic              csr_adr_space_i,
  input  logic              csr_hpmtc_i,
  input  logic              csr_6_i,

  input  logic              csr_info_new_insn_i,
  input  logic              trap_i,
  input  logic              mret_i,
  input  logic [1:0]        mcause30_i,
  input  logic              mcause_int_i,
  output logic              mtie_o,

  // ram interface
  output logic                  ram_we_o,
  output logic [ADR_WIDTH-1:0]  ram_waddr_o,
  output logic [31:0]           ram_wdata_o,
  output logic [ADR_WIDTH-1:0]  ram_raddr_ab_o,
  output logic [ADR_WIDTH-1:0]  ram_raddr_b_o,
  input  logic [31:0]           ram_rdata_ab_i,
  input  logic [31:0]           ram_rdata_b_i

`ifdef RISCV_FORMAL
  ,
  output logic [31:0]       dbg_res_o
`endif
);

localparam REGW = 32;

// TODO: adapt control logic for DP

// Timing
// ======
// LOGIC:       (F) write rd (D1) read regs
// BRAM:        (F) write rd (D1) read rs1 -> outreg (D2) rs1 into shifreg, read rs2 -> outreg (D3) rs2 into shifteg
// BRAM_BP:     (F) write rd (D1) read rs1 -> outreg (D2) rs1 into shiftreg, read rs2 -> outreg (C1) mux outreg into ALU
// BRAM_DP:     (F) write rd (D1) read rs1, rs2 -> outreg (D2) rs1, rs1 into shiftreg
// BRAM_DP_BP:  (F) write rd (D1) read rs1, rs2 -> outreg (C1) mux outreg into alu

// CSR:
// ICYC1: read CSR into rb_r; write rd_r into CSR
// ICYC2:                     write rd_r into rd

logic [REGW-1:0]      ra_r;
logic [REGW-1:0]      rb_r;
logic [REGW-1:0]      rd_r;

logic                 ram_rs1_en;
logic                 ram_rs2_en;
logic                 ram_rd_en;

// Read data after considering CSR
logic [REGW-1:0]      rdata_ab;
logic [REGW-1:0]      rdata_b;

// Addresses to ram
logic [ADR_WIDTH-1:0] rs_ab_ram;
logic [ADR_WIDTH-1:0] rs_b_ram;

logic [ADR_WIDTH-1:0] rd_ram;

// sp
logic act_r;
logic ram_stb_dly_r;

// csr
logic csr_wstb;
logic [31:0] csr_rdata_ab;
logic [31:0] csr_rdata_b;


// --- helper ---

/* verilator lint_off WIDTHEXPAND */
localparam SP     = (RF_TYPE == "BRAM")     || (RF_TYPE == "BRAM_BP");
localparam SP_BP  = (RF_TYPE == "BRAM_BP");
localparam DP     = (RF_TYPE == "BRAM_DP")  || (RF_TYPE == "BRAM_DP_BP");
localparam DP_BP  = (RF_TYPE == "BRAM_DP_BP");
/* verilator lint_on WIDTHEXPAND */

// --- dont write R0 ---

assign ram_we_o     = rf_wstb_i & rf_we_i & (rd_ram != 'b0) & ram_rd_en;
assign ram_wdata_o  = rd_r;

// --- src dst select ---



generate
  /* verilator lint_off WIDTHEXPAND */
  if ((CONF == "INT") | (CONF == "CSR")) begin
  /* verilator lint_on WIDTHEXPAND */
    assign ram_rs1_en = ~(csr_adr_space_i & csr_hpmtc_i);
    assign ram_rs2_en = ~(csr_adr_space_i & (csr_hpmtc_i | (~rf_rs2_i[0] & csr_6_i)));
    assign ram_rd_en  = ram_rs2_en;
  end else begin
    assign ram_rs1_en = 1'b1;
    assign ram_rs2_en = 1'b1;
    assign ram_rd_en  = 1'b1;
  end
endgenerate


// --- output FF bypass muxes ---

generate
  if (SP) begin
    assign rf_ra_o    = ra_r[BWIDTH-1:0];
    if (SP_BP) begin
      assign rf_rb_o  = (ram_stb_dly_r & ~csr_adr_space_i) ? rdata_ab[BWIDTH-1:0] : rb_r[BWIDTH-1:0];
    end else begin
      assign rf_rb_o  = rb_r[BWIDTH-1:0];
    end
  end

  if (DP) begin
    if (DP_BP) begin
      assign rf_ra_o  = (ram_stb_dly_r & ~csr_adr_space_i) ? rdata_ab[BWIDTH-1:0] : ra_r[BWIDTH-1:0];
      assign rf_rb_o  = (ram_stb_dly_r & ~csr_adr_space_i) ? rdata_b[BWIDTH-1:0]  : rb_r[BWIDTH-1:0];
    end else begin
      assign rf_ra_o  = ra_r[BWIDTH-1:0];
      assign rf_rb_o  = rb_r[BWIDTH-1:0];
    end
  end
endgenerate



// --- state machine for single port reads ---

always_ff @(posedge clk_i) begin
  if (~rst_in) begin
    act_r         <= 'b0;
    ram_stb_dly_r <= 'b0;
  end else begin

    // cycle results if not read new
    if (rf_shft_i & ~rf_rstb_i) begin
      ra_r <= { ra_r[BWIDTH-1:0], ra_r[31:BWIDTH]};
      rb_r <= { rb_r[BWIDTH-1:0], rb_r[31:BWIDTH]};
    end

    // csr: reg ok in write cycle, keep shifting
    // to load correct data for second cycle
    if (rf_shft_i & (~rf_wstb_i | csr_adr_space_i) ) begin
      if (rf_we_i) begin
        rd_r  <= { rf_res_i, rd_r[31:BWIDTH]};
      end else begin
        rd_r  <= { rd_r[BWIDTH-1:0], rd_r[31:BWIDTH]};
      end
    end

    // -- Single Port RAM ---
    if (SP) begin
      if (rf_rstb_i) begin
        act_r <= ~act_r;
      end
      ram_stb_dly_r <= rf_rstb_i;

      if (rf_rstb_i | ram_stb_dly_r) begin
        if (SP_BP) begin
          if (act_r) begin
            ra_r <= rdata_ab;
          end else begin
            rb_r <= { rdata_ab[BWIDTH-1:0], rdata_ab[31:BWIDTH]};;
          end
        end else begin
          rb_r <= rdata_ab;
          if (ram_stb_dly_r) begin
            ra_r <= rb_r;
          end
        end
      end
    end

    // -- Dual Port RAM ---
    if (DP) begin

      // can be replace this with ~icyc1&~icyc2&lsb or
      // does it make the critical path longer?
      ram_stb_dly_r <= rf_rstb_i;

      if (DP_BP & ram_stb_dly_r) begin
        ra_r <= { rdata_ab[BWIDTH-1:0], rdata_ab[31:BWIDTH]};
        rb_r <= { rdata_b[BWIDTH-1:0], rdata_b[31:BWIDTH]};
      end

      if (~DP_BP & rf_rstb_i) begin
        ra_r <= rdata_ab;
        rb_r <= rdata_b;
      end
    end
  end
end

assign ram_waddr_o    = rd_ram;
assign ram_raddr_ab_o = rs_ab_ram;
assign ram_raddr_b_o  = rs_b_ram;


generate

  // WITH CSRs
  //

  /* verilator lint_off WIDTHEXPAND */
  if ((CONF == "CSR") | (CONF == "INT")) begin
  //
    assign rd_ram = trap_i          ? {2'b10, 4'b0001}    :
                    csr_adr_space_i ? {2'b10, rf_rs2_i[3:0]} :
                                      rf_rd_i;
  /* verilator lint_on WIDTHEXPAND */
    // --- Single Port Ram ---
    if (SP) begin
      assign rs_b_ram = 'b0;
      assign rdata_b  = 'b0;

      always_comb begin
        rs_ab_ram = {{ADR_WIDTH-5{1'b0}}, rf_rs1_i};

        if (~act_r) begin
          if (~ram_rs1_en)
            rs_ab_ram = 'b0;
        end else begin
          if (csr_adr_space_i) begin
            rs_ab_ram = {2'b10, rf_rs2_i[3:0]};
          end else begin
            rs_ab_ram = {{ADR_WIDTH-5{1'b0}}, rf_rs2_i};
          end

          if (~ram_rs2_en)
            rs_ab_ram = 'b0;
        end

        //
        if (trap_i) begin
          rs_ab_ram = {2'b10, 4'b0011};
        end

        // TODO: merge with trap_i as most bits are identical
        // TODO: can be both or ra
        if (mret_i) begin
          rs_ab_ram = {2'b10, 4'b0001};
        end
      end

      assign rdata_ab = csr_rdata_ab | csr_rdata_b | ram_rdata_ab_i;
    end

    // --- Dual Port RAM ---
    if (DP) begin

      always_comb begin
        rs_ab_ram = {{ADR_WIDTH-5{1'b0}}, rf_rs1_i};
        if (~ram_rs1_en)
          rs_ab_ram = 'b0;

        if (csr_adr_space_i) begin
          rs_b_ram = {2'b10, rf_rs2_i[3:0]};
        end else begin
          rs_b_ram = {{ADR_WIDTH-5{1'b0}}, rf_rs2_i};
        end

        if (~ram_rs2_en) begin
            rs_b_ram = 'b0;
        end

        if (trap_i) begin
          //
          rs_ab_ram = {2'b10, 4'b0011};
          rs_b_ram = {2'b10, 4'b0011};
        end

        // TODO: merge with trap_i as most bits are identical
        // TODO: can be both or ra
        if (mret_i) begin
          //
          rs_ab_ram = {2'b10, 4'b0001};
          rs_b_ram = {2'b10, 4'b0001};
        end

      end
      assign rdata_ab = csr_rdata_ab | ram_rdata_ab_i;
      assign rdata_b  = csr_rdata_b | ram_rdata_b_i;

    end

  end else begin
    assign rd_ram = rf_rd_i;

    // --- Single Port RAM ---
    if (SP) begin
      assign rs_ab_ram    = act_r ? rf_rs2_i : rf_rs1_i;
      assign rs_b_ram     = 'b0;
      assign rdata_ab     = ram_rdata_ab_i;
    end

    // --- Dual Port RAM ---
    if (DP) begin
      assign rs_ab_ram  = rf_rs1_i;
      assign rs_b_ram   = rf_rs2_i;
      assign rdata_ab   = ram_rdata_ab_i;
      assign rdata_b    = ram_rdata_b_i;
    end
  end
endgenerate

// --- csr ---

generate

  logic csr_rs1_en;
  logic csr_rs2_en;

  if (SP || SP_BP) begin
    assign csr_rs1_en = ~ram_rs1_en & ~act_r;
    assign csr_rs2_en = ~ram_rs2_en & ~act_r;
  end else begin
    assign csr_rs1_en = ~ram_rs1_en;
    assign csr_rs2_en = ~ram_rs2_en;
  end

  /* verilator lint_off WIDTHEXPAND */
  if ((CONF == "INT") || (CONF == "CSR")) begin
  /* verilator lint_on WIDTHEXPAND */
    fazyrv_csr #( .CONF (CONF)) i_fazyrv_csr (
      .clk_i                ( clk_i   ),
      .rst_in               ( rst_in  ),

      .csr_wstb_i           ( csr_wstb            ),
      .csr_rs_i             ( rf_rs2_i            ),
      .csr_hpmtc_i          ( csr_hpmtc_i         ),
      .csr_info_new_insn_i  ( csr_info_new_insn_i ),
      .csr_rs1_en_i         ( csr_rs1_en          ),
      .csr_rs2_en_i         ( csr_rs2_en          ),

      .wdata_i              ( rd_r          ),
      .rdata_ab_o           ( csr_rdata_ab  ),
      .rdata_b_o            ( csr_rdata_b   ),

      .trap_i               ( trap_i        ),
      .mret_i               ( mret_i        ),
      .mcause30_i           ( mcause30_i    ),
      .mcause_int_i         ( mcause_int_i  ),
      .mtie_o               ( mtie_o        )
    );

  assign csr_wstb = rf_wstb_i & rf_we_i & ~ram_rd_en;

  //if (SP | SP_BP) begin
  //  assign rdata_ab_o = act_r ? rdata_b : rdata_a;
  //end else begin
  //  assign rdata_ab_o = rdata_a;
  //  assign rdata_b_o  = rdata_b;
  //end


  end else begin
    assign csr_rdata_ab = 'b0;
    assign csr_rdata_b  = 'b0;
    assign mtie_o       = 'b0;
  end
endgenerate



`ifdef RISCV_FORMAL
// We shift into the buffer register also when rd==0, we this is not written
// to the RAM. Thus, we need to mask with zero here.
assign dbg_res_o = (rf_rd_i != 0) ? rd_r : 'b0;
`endif

endmodule

