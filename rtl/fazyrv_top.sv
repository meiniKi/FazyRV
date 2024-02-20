// Copyright (c) 2023 Meinhard Kissich
// -----------------------------------------------------------------------------
// File  :  fazyrv_top.sv
// Usage :  FazyRV core including the register file.
//
// Param
//  - BWIDTH      Size of the chunks, i.e., the data path.
//                [1 (bit serial), 2, 4, or 8]
//
//  - CONF        Configuration of the processor.
//                ["MIN": no interrupts, no CSRs;
//
//                "INT": simple interrupt by fixed mtval, no CSRs;
//                "CSR": a limited set of CSRs are available]
//  - MTVAL       Initial value of mtval if available.
//
//  - BOOTADR     Address of first instruction to be fetched.
//
//  - RFTYPE      Implementation of the register file.
//                ["LOGIC": register file as distributed ram
//                "BRAM": register file as block ram.
//                "BRAM_BP": block ram with bypassing muxes.
//                "BRAM_DP": block ram with two read ports.
//                "BRAM_DP_BP": block ram with two read ports and bypassing muxes.
//
//   - MEMDLY1    Use memory with a fixed delay of 1 clock cycle instead of
//                standard Wishbone interface.
//
// Ports
//  - clk_i       Clock input, sensitive to rising edge.
//  - rst_in      Reset, low active.
//  - tirq_i      Timer interrupt input.
//  - trap_o      Informing about trap.
//
//  - wb_imem_stb_o Wishbone instruction memory interface.
//  - wb_imem_cyc_o
//  - wb_imem_adr_o
//  - wb_imem_dat_i
//  - wb_imem_ack_i
//
//  - wb_dmem_cyc_o Wishbone data memory interface.
//  - wb_dmem_stb_o
//  - wb_dmem_we_o
//  - wb_dmem_ack_i 
//  - wb_dmem_be_o
//  - wb_dmem_dat_i 
//  - wb_dmem_adr_o 
//  - wb_dmem_dat_o 
//
//  - RVFI_OUTPUTS  RVFI used for formal checks.
//
//
//
//
//
// -----------------------------------------------------------------------------
//     / \       Initial version for evaluating scalability.       / \
//    / | \             _Not_ recommended for use.                / | \
//   /  .  \   Please use the version in `main` branch instead.  /  .  \
// -----------------------------------------------------------------------------

module fazyrv_top #(
  parameter BWIDTH      = 1,
  parameter CONF        = "MIN",
  parameter MTVAL       = 'b0,
  parameter BOOT_ADDR   = 'h0,
  parameter RF_TYPE     = "BRAM_DP",
  parameter MEM_DLY_1   = 0
) (
  input  logic              clk_i,
  input  logic              rst_in,
  input  logic              tirq_i,
  output logic              trap_o,

  output logic              wb_imem_stb_o,
  output logic              wb_imem_cyc_o,
  output logic [31:0]       wb_imem_adr_o,
  input  logic [31:0]       wb_imem_dat_i,
  input  logic              wb_imem_ack_i,

  output logic              wb_dmem_cyc_o,
  output logic              wb_dmem_stb_o,
  output logic              wb_dmem_we_o,
  input  logic              wb_dmem_ack_i,
  output logic [3:0]        wb_dmem_be_o,
  input  logic [31:0]       wb_dmem_dat_i,
  output logic [31:0]       wb_dmem_adr_o,
  output logic [31:0]       wb_dmem_dat_o
`ifdef RISCV_FORMAL
  ,
  output logic        rvfi_valid,
  output logic [63:0] rvfi_order,
  output logic [31:0] rvfi_insn,
  output logic        rvfi_trap,
  output logic        rvfi_halt,
  output logic        rvfi_intr,
  output logic [1:0]  rvfi_mode,
  output logic [1:0]  rvfi_ixl,
  output logic [4:0]  rvfi_rs1_addr,
  output logic [4:0]  rvfi_rs2_addr,
  output logic [31:0] rvfi_rs1_rdata,
  output logic [31:0] rvfi_rs2_rdata,
  output logic [4:0]  rvfi_rd_addr,
  output logic [31:0] rvfi_rd_wdata,
  output logic [31:0] rvfi_pc_rdata,
  output logic [31:0] rvfi_pc_wdata,
  output logic [31:0] rvfi_mem_addr,
  output logic [3:0]  rvfi_mem_rmask,
  output logic [3:0]  rvfi_mem_wmask,
  output logic [31:0] rvfi_mem_rdata,
  output logic [31:0] rvfi_mem_wdata
`endif
);

logic               rf_shft;
logic               rf_ram_wstb;
logic               rf_ram_rstb;
logic [4:0]         rf_rs1;
logic [4:0]         rf_rs2;
logic [4:0]         rf_rd;
logic               rf_we;
logic [BWIDTH-1:0]  rf_ra;
logic [BWIDTH-1:0]  rf_rb;
logic [BWIDTH-1:0]  rf_res;
logic               rf_csr;
logic               rf_csr_6;
logic               rf_hpmtc;
logic               rf_trap;
logic               rf_mret;
logic [1:0]         rf_mcause30;
logic               rf_mcause_int;
logic               rf_mtie;


`ifdef RISCV_FORMAL
  logic [31:0] fv_res;
  always_ff @(posedge clk_i) begin
    if (wb_imem_ack_i)  rvfi_rd_wdata <= 'b0;
    if (rf_we)          rvfi_rd_wdata <= fv_res;
  end
`endif


fazyrv_core #(
  .BWIDTH     ( BWIDTH    ),
  .CONF       ( CONF      ),
  .MTVAL      ( MTVAL     ),
  .BOOT_ADDR  ( BOOT_ADDR ),
  .RF_TYPE    ( RF_TYPE   ),
  .MEM_DLY_1  ( MEM_DLY_1 )
) i_fazyrv_core (
  .clk_i            ( clk_i             ),
  .rst_in           ( rst_in            ),
  .tirq_i           ( tirq_i            ),
  .trap_o           ( trap_o            ),

  .wb_imem_stb_o    ( wb_imem_stb_o     ),
  .wb_imem_cyc_o    ( wb_imem_cyc_o     ),
  .wb_imem_adr_o    ( wb_imem_adr_o     ),
  .wb_imem_dat_i    ( wb_imem_dat_i     ),
  .wb_imem_ack_i    ( wb_imem_ack_i     ),

  .wb_dmem_cyc_o    ( wb_dmem_cyc_o     ),
  .wb_dmem_stb_o    ( wb_dmem_stb_o     ),
  .wb_dmem_we_o     ( wb_dmem_we_o      ),
  .wb_dmem_ack_i    ( wb_dmem_ack_i     ),
  .wb_dmem_be_o     ( wb_dmem_be_o      ),
  .wb_dmem_dat_i    ( wb_dmem_dat_i     ),
  .wb_dmem_adr_o    ( wb_dmem_adr_o     ),
  .wb_dmem_dat_o    ( wb_dmem_dat_o     ),

  .rf_shft_o        ( rf_shft           ),
  .rf_ram_wstb_o    ( rf_ram_wstb       ),
  .rf_ram_rstb_o    ( rf_ram_rstb       ),
  .rf_rs1_o         ( rf_rs1            ),
  .rf_rs2_o         ( rf_rs2            ),
  .rf_rd_o          ( rf_rd             ),
  .rf_we_o          ( rf_we             ),
  .rf_ra_i          ( rf_ra             ),
  .rf_rb_i          ( rf_rb             ),
  .rf_res_o         ( rf_res            ),
  .rf_hpmtc_o       ( rf_hpmtc          ),
  .rf_csr_o         ( rf_csr            ),
  .rf_csr_6_o       ( rf_csr_6          ),
  .rf_trap_o        ( rf_trap           ),
  .rf_mret_o        ( rf_mret           ),
  .rf_mcause30_o    ( rf_mcause30       ),
  .rf_mcause_int_o  ( rf_mcause_int     ),
  .rf_mtie_i        ( rf_mtie           )
`ifdef RISCV_FORMAL
  ,
  `RVFI_CONN,
`endif
);

localparam REGW       = 32;
localparam NO_X_REGS  = 32;
localparam NO_CSRS    = (CONF == "CSR") ? 8 : 0;
localparam MEM_DEPTH  = NO_X_REGS+NO_CSRS;
localparam ADR_WIDTH  = $clog2(MEM_DEPTH);


// -----------------------------------------------
// -----------------------------------------------

logic                 ram_we;
logic [ADR_WIDTH-1:0] ram_waddr;
logic [31:0]          ram_wdata;
logic [ADR_WIDTH-1:0] ram_raddr_ab;
logic [ADR_WIDTH-1:0] ram_raddr_b;
logic [31:0]          ram_rdata_ab;
logic [31:0]          ram_rdata_b;

//
// RF_TYPE Logic only available when used _not_ with CSRs.
// Adding CSRs to the distributed regfile implementation
// would introduce area overhead (output registers to buffer
// CSR) that is considered to be unreasonable. Switch to BRAM
// implementation instead.
//

generate
  /* verilator lint_off WIDTHEXPAND */
  if ((CONF == "CSR") && (RF_TYPE == "LOGIC")) begin
    initial $error("[ERR] Please use the BRAM implementation for CSR support.");
  end
  /* verilator lint_on WIDTHEXPAND */

  /* verilator lint_off WIDTHEXPAND */
  if (RF_TYPE == "LOGIC") begin
  /* verilator lint_on WIDTHEXPAND */
  // RF LUT
  //
    fazyrv_rf_lut #( .BWIDTH (BWIDTH) ) i_fazyrv_rf_lut (
      .clk_i                ( clk_i         ),
      .rst_in               ( rst_in        ),
      .shft_i               ( rf_shft       ),
      .ram_wstb_i           ( rf_ram_wstb   ),
      .ram_rstb_i           ( rf_ram_rstb   ),
      .rs1_i                ( rf_rs1        ),
      .rs2_i                ( rf_rs2        ),
      .rd_i                 ( rf_rd         ),
      .ra_o                 ( rf_ra         ),
      .rb_o                 ( rf_rb         ),
      .res_i                ( rf_res        ),
      .we_i                 ( rf_we         )
`ifdef RISCV_FORMAL
      ,
      .dbg_res_o  ( fv_res  )  
`endif
    );
  end else begin
  // RF BRAM
  //
    fazyrv_rf #(
      .BWIDTH     ( BWIDTH    ),
      .RF_TYPE    ( RF_TYPE   ),
      .CONF       ( CONF      ),
      .ADR_WIDTH  ( ADR_WIDTH )
    ) i_fazyrv_regfile (
      .clk_i                ( clk_i         ),
      .rst_in               ( rst_in        ),
      .rf_shft_i            ( rf_shft       ),
      .rf_wstb_i            ( rf_ram_wstb   ),
      .rf_rstb_i            ( rf_ram_rstb   ),
      .rf_rs1_i             ( rf_rs1        ),
      .rf_rs2_i             ( rf_rs2        ),
      .rf_ra_o              ( rf_ra         ),
      .rf_rb_o              ( rf_rb         ),
      .rf_rd_i              ( rf_rd         ),
      .rf_res_i             ( rf_res        ),
      .rf_we_i              ( rf_we         ),

      .csr_adr_space_i      ( rf_csr        ),
      .csr_hpmtc_i          ( rf_hpmtc      ),
      .csr_6_i              ( rf_csr_6      ),

      .csr_info_new_insn_i  ( wb_imem_ack_i ),
      .trap_i               ( rf_trap       ),
      .mret_i               ( rf_mret       ),
      .mcause30_i           ( rf_mcause30   ),
      .mcause_int_i         ( rf_mcause_int ),
      .mtie_o               ( rf_mtie       ),

      .ram_we_o             ( ram_we        ),
      .ram_waddr_o          ( ram_waddr     ),
      .ram_wdata_o          ( ram_wdata     ),
      .ram_raddr_ab_o       ( ram_raddr_ab  ),
      .ram_raddr_b_o        ( ram_raddr_b   ),
      .ram_rdata_ab_i       ( ram_rdata_ab  ),
      .ram_rdata_b_i        ( ram_rdata_b   )
`ifdef RISCV_FORMAL
      ,
      .dbg_res_o  ( fv_res  )  
`endif
        );
      end

endgenerate

// -----------------------------------------------
// -----------------------------------------------

generate
  /* verilator lint_off WIDTHEXPAND */
  if ((RF_TYPE == "BRAM_DP") || (RF_TYPE == "BRAM_DP_BP")) begin
  /* verilator lint_on WIDTHEXPAND */
  // --- BRAM Dual Port ---
  //
    fazyrv_ram_dp #(
      .REGW       ( REGW      ),
      .ADRW       ( ADR_WIDTH ),
      .DEPTH      ( MEM_DEPTH )
    ) i_bram_dp (
      .clk_i      ( clk_i ),
`ifdef RISCV_FORMAL
      .we_i       ( ram_we & rst_in  ),
`else
      .we_i       ( ram_we  ),
`endif
      .waddr_i    ( ram_waddr     ),
      .wdata_i    ( ram_wdata     ),
      .raddr_a_i  ( ram_raddr_ab  ),
      .rdata_a_o  ( ram_rdata_ab  ),
      .raddr_b_i  ( ram_raddr_b   ),
      .rdata_b_o  ( ram_rdata_b   )
    );

  /* verilator lint_off WIDTHEXPAND */
  end else if ((RF_TYPE == "BRAM") || (RF_TYPE == "BRAM_BP")) begin
  /* verilator lint_on WIDTHEXPAND */
  // --- BRAM Single Port ---
  //
    fazyrv_ram_sp #(
      .REGW     ( REGW      ),
      .ADRW     ( ADR_WIDTH ),
      .DEPTH    ( MEM_DEPTH )
    ) i_bram_sp (
      .clk_i    ( clk_i ),
`ifdef RISCV_FORMAL
      .we_i     ( ram_we & rst_in  ),
`else
      .we_i     ( ram_we  ),
`endif
      .waddr_i  ( ram_waddr     ),
      .wdata_i  ( ram_wdata     ),
      .raddr_i  ( ram_raddr_ab  ),
      .rdata_o  ( ram_rdata_ab  )
    );

  end
endgenerate

endmodule
