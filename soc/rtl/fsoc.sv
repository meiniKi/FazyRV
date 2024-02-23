// Copyright (c) 2023 - 2024 Meinhard Kissich
// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
// File  :  fsoc.sv
// Usage :  FazyRV SoC to run the Embench bechmark suite. 
// Param
//  - CHUNKSIZE Width of the input vectors.
//  - CONF      Configuration of the processor (see FazyRV core).
//  - MTVAL     Initial value of mtval if available (see FazyRV core).
//  - BOOTADR   Address of first instruction to be fetched (see FazyRV core).
//  - RFTYPE    Implementation of the register (see FazyRV core).
//  - MEMFILE   Firmware.
//  - MEMSIZE   Memory size in _words_.
//  - MEMDLY1   Flag whether to use memory with fixed delay (see FazyRV core).
//  - GPOCNT    Number of outputs.
//
// Ports
//  - clk_i     Clock input.
//  - rst_in    Reset, low active.
//  - gpi_i     General purpose inputs.
//  - gpo_o     General purpose outputs.
// -----------------------------------------------------------------------------

module fsoc #( 
  parameter CHUNKSIZE = 8,
  parameter CONF      = "MIN",
  parameter RFTYPE    = "BRAM",
  parameter MTVAL     = 'h0,
  parameter BOOTADR   = 'h0,
  parameter MEMFILE   = "",
  parameter MEMSIZE   = 64,
  parameter MEMDLY1   = 0,
  parameter GPOCNT    = 1
) (
  input  logic              clk_i,
  input  logic              rst_in,

  input  logic              gpi_i,
  output logic [GPOCNT-1:0] gpo_o
);

// GPIO: 0x1xxxxxxx

logic         tirq_i = 1'b0;
logic         trap_o;

logic         wb_cpu_imem_stb;
logic         wb_cpu_imem_cyc;
logic [31:0]  wb_cpu_imem_adr;
logic [31:0]  wb_cpu_imem_rdat;
logic         wb_cpu_imem_ack;

logic         wb_cpu_dmem_cyc;
logic         wb_cpu_dmem_stb;
logic         wb_cpu_dmem_we;
logic         wb_cpu_dmem_ack;
logic [3:0]   wb_cpu_dmem_be;
logic [31:0]  wb_cpu_dmem_rdat;
logic [31:0]  wb_cpu_dmem_adr;
logic [31:0]  wb_cpu_dmem_wdat;

logic         wb_mem_cyc;
logic         wb_mem_stb;
logic         wb_mem_we;
logic         wb_mem_ack;
logic [3:0]   wb_mem_be;
logic [31:0]  wb_mem_rdat;
logic [31:0]  wb_mem_adr;
logic [31:0]  wb_mem_wdat;

logic         wb_gpio_cyc;
logic         wb_gpio_stb;
logic         wb_gpio_we;
logic         wb_gpio_ack;
logic [3:0]   wb_gpio_be;
logic [31:0]  wb_gpio_rdat;
logic [31:0]  wb_gpio_wdat;

logic         sel_gpio;

`ifndef SIGNATURE
assign sel_gpio = wb_mem_adr[28];
`else
assign sel_gpio = 1'b0;
`endif

assign wb_cpu_imem_rdat = wb_mem_rdat;
assign wb_cpu_dmem_rdat = sel_gpio ? wb_gpio_rdat : wb_mem_rdat;

assign wb_cpu_imem_ack = wb_mem_ack & wb_cpu_imem_stb;
assign wb_cpu_dmem_ack = (wb_gpio_ack | wb_mem_ack) & wb_cpu_dmem_stb;

assign wb_mem_adr   = wb_cpu_imem_stb ? wb_cpu_imem_adr : wb_cpu_dmem_adr;
assign wb_mem_wdat  = wb_cpu_dmem_wdat;
assign wb_mem_be    = wb_cpu_dmem_be;
assign wb_mem_we    = wb_cpu_dmem_we & wb_cpu_dmem_stb;
assign wb_mem_cyc   = ~sel_gpio & (wb_cpu_imem_stb | wb_cpu_dmem_stb);
assign wb_mem_stb   = wb_mem_cyc;

assign wb_gpio_cyc   = sel_gpio & wb_cpu_dmem_stb;
assign wb_gpio_stb   = wb_gpio_cyc;
assign wb_gpio_we    = wb_cpu_dmem_we;
assign wb_gpio_be    = wb_cpu_dmem_be;
assign wb_gpio_wdat  = wb_cpu_dmem_wdat;


gpio #(.GPOCNT(GPOCNT)) i_gpio (
  .clk_i  ( clk_i         ),
  .cyc_i  ( wb_gpio_cyc   ),
  .stb_i  ( wb_gpio_stb   ),
  .we_i   ( wb_gpio_we    ),
  .ack_o  ( wb_gpio_ack   ),
  .be_i   ( wb_gpio_be    ),
  .dat_i  ( wb_gpio_wdat  ),
  .dat_o  ( wb_gpio_rdat  ),
  .gpi_i  ( gpi_i         ),
  .gpo_o  ( gpo_o         )
);

(* keep *) wb_ram #(.DEPTH(MEMSIZE/4), .MEMFILE(MEMFILE)) i_mem (
  .clk_i  ( clk_i             ),
  .cyc_i  ( wb_mem_cyc        ),
  .stb_i  ( wb_mem_stb        ),
  .we_i   ( wb_mem_we         ),
  .ack_o  ( wb_mem_ack        ),
  .be_i   ( wb_mem_be         ),
  .adr_i  ( wb_mem_adr[$clog2(MEMSIZE/4)+1:2]),
  .dat_i  ( wb_mem_wdat       ),
  .dat_o  ( wb_mem_rdat       )
);

logic imem_ack;

generate
if (MEMDLY1 == 1) begin
  logic emu_ack_imem_r;

  always_ff @(posedge clk_i) begin
    emu_ack_imem_r <= wb_cpu_imem_stb;
  end
  assign imem_ack = emu_ack_imem_r;
end else begin
  assign imem_ack = wb_cpu_imem_ack;
end
endgenerate


fazyrv_top #( 
  .CHUNKSIZE  ( CHUNKSIZE ),
  .CONF       ( CONF      ),
  .MTVAL      ( MTVAL     ),
  .BOOTADR    ( BOOTADR   ),
  .RFTYPE     ( RFTYPE    ),
  .MEMDLY1    ( MEMDLY1   )
) i_fazyrv_core (
  .clk_i          ( clk_i             ),
  .rst_in         ( rst_in            ),
  .tirq_i         ( tirq_i            ),
  .trap_o         ( trap_o            ),

  .wb_imem_stb_o  ( wb_cpu_imem_stb   ),
  .wb_imem_cyc_o  ( wb_cpu_imem_cyc   ),
  .wb_imem_adr_o  ( wb_cpu_imem_adr   ),
  .wb_imem_dat_i  ( wb_cpu_imem_rdat  ),
  .wb_imem_ack_i  ( imem_ack          ),

  .wb_dmem_cyc_o  ( wb_cpu_dmem_cyc   ),
  .wb_dmem_stb_o  ( wb_cpu_dmem_stb   ),
  .wb_dmem_we_o   ( wb_cpu_dmem_we    ),
  .wb_dmem_ack_i  ( wb_cpu_dmem_ack   ),
  .wb_dmem_be_o   ( wb_cpu_dmem_be    ),
  .wb_dmem_dat_i  ( wb_cpu_dmem_rdat  ),
  .wb_dmem_adr_o  ( wb_cpu_dmem_adr   ),
  .wb_dmem_dat_o  ( wb_cpu_dmem_wdat  )
);

// Adopted from SERV
`ifdef SIGNATURE
logic sig_en;
logic halt_en;

assign halt_en = (wb_mem_adr[31:28] == 4'h9) & wb_mem_cyc & wb_mem_ack;
assign sig_en = (wb_mem_adr[31:28] == 4'h8) & wb_mem_cyc & wb_mem_ack;

logic [1023:0] signature_file;

integer f = 0;

initial
  /* verilator lint_off WIDTH */
  if ($value$plusargs("signature=%s", signature_file)) begin
    $display("Writing signature to %0s", signature_file);
    f = $fopen(signature_file, "w");
  end
  /* verilator lint_on WIDTH */

  always @(posedge clk_i) begin
    if (sig_en & (f != 0))
      $fwrite(f, "%c", wb_mem_wdat[7:0]);
    else if(halt_en) begin
      $display("Test complete");
      $finish;
    end
  end
`endif

endmodule
