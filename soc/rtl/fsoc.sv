
module fsoc #( 
  parameter BWIDTH      = 8,
  parameter CONF        = "MIN",
  parameter RF_TYPE     = "BRAM",
  parameter MTVAL       = 'h0,
  parameter BOOT_ADDR   = 'h0,
  parameter MEMFILE     = "",
  parameter MEMSIZE     = 64,
  parameter MEM_DLY_1   = 0
) (
  input  logic        clk_i,
  input  logic        rst_in,

  input  logic        gpi_i,
  output logic        gpo_o
);

// GPIO: 0x1xxxxxxx

logic        tirq_i = 1'b0;
logic        trap_o;

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


gpio i_gpio (
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

(* keep *) wb_ram #(.depth(MEMSIZE/4), .memfile(MEMFILE)) i_mem (
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

// This can be optimized and included in the processors control
// logic
generate
if (MEM_DLY_1 == 1) begin
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
  .BWIDTH     ( BWIDTH    ),
  .CONF       ( CONF      ),
  .MTVAL      ( MTVAL     ),
  .BOOT_ADDR  ( BOOT_ADDR ),
  .RF_TYPE    ( RF_TYPE   ),
  .MEM_DLY_1  ( MEM_DLY_1 )
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
