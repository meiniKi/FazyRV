// Copyright (c) 2023 - 2024 Meinhard Kissich
// -----------------------------------------------------------------------------
// File  :  tb.sv
// Usage :  Testbench to execute the riscvtests.
// -----------------------------------------------------------------------------

`timescale 1 ns / 1 ps

module tb;

localparam CHUNKSIZE  = `CHUNKSIZE;
localparam RFTYPE     = `RFTYPE;
localparam CONF       = `CONF;
localparam MEMDLY1    = `MEMDLY1;

localparam MTVAL      = 'h0;
localparam BOOTADR    = 'h0;

logic clk   = 1'b0;
logic rst_n = 1'b0;

always #5 clk = ~clk;

initial begin
  rst_n <= 1'b0;
  repeat (100) @(posedge clk);
  rst_n <= 1;
end

initial begin
  if ($test$plusargs("vcd")) begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
  end
  repeat (600000) @(posedge clk);
  $display("TIMEOUT");
  $fatal;
end

// --- mcu ---

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

(* keep *) logic [31:0]  scratch_r;
logic to_scratch;

assign to_scratch = wb_mem_adr[28];

assign wb_cpu_imem_rdat = wb_mem_rdat;
assign wb_cpu_dmem_rdat = wb_mem_rdat;

assign wb_cpu_imem_ack = wb_mem_ack & wb_cpu_imem_stb;
assign wb_cpu_dmem_ack = (to_scratch | wb_mem_ack) & wb_cpu_dmem_stb;

assign wb_mem_adr   = wb_cpu_imem_stb ? wb_cpu_imem_adr : wb_cpu_dmem_adr;
assign wb_mem_wdat  = wb_cpu_dmem_wdat;
assign wb_mem_be    = wb_cpu_dmem_be;
assign wb_mem_we    = wb_cpu_dmem_we & wb_cpu_dmem_stb;
assign wb_mem_stb   = ~to_scratch & (wb_cpu_imem_stb | wb_cpu_dmem_stb); 
assign wb_mem_cyc   = ~to_scratch & (wb_cpu_imem_cyc | wb_cpu_dmem_cyc);

// Hack when solution when not traps are implemented.
reg [31:0] shift_reg = 32'd0;
reg prev_cpu_dmem_stb;

always_ff @(posedge clk) begin
  if (to_scratch & ~prev_cpu_dmem_stb & wb_cpu_dmem_stb) begin
    scratch_r <= wb_mem_wdat;
    shift_reg <= {shift_reg[23:0], wb_mem_wdat[7:0]};  // shift in new data
  end
end

always_ff @(posedge clk) begin
  if (shift_reg == {"D", "O", "N", "E"}) begin
    $finish;
  end
  if (shift_reg[23:0] == {"E", "R", "R"}) begin
    $fatal;
  end
end

always @(posedge clk) begin
  prev_cpu_dmem_stb <= wb_cpu_dmem_stb;
  if (to_scratch & ~prev_cpu_dmem_stb & wb_cpu_dmem_stb) begin
    $write("%c", wb_mem_wdat);
    $fflush();
  end
end

// Can be included when traps are implemented
//always @(posedge clk) begin
//  if (rst_n && trap) begin
//    repeat (10) @(posedge clk);
//    $display("TRAP");
//    $finish;
//  end
//end

logic imem_ack;

generate
if (MEMDLY1 == 1) begin
  logic emu_ack_imem_r;

  always_ff @(posedge clk) begin
    emu_ack_imem_r <= wb_cpu_imem_stb;
  end
  assign imem_ack = emu_ack_imem_r;
end else begin
  assign imem_ack = wb_cpu_imem_ack;
end
endgenerate

wb_ram #(.depth(32768), .memfile("firmware/firmware.hex")) i_mem (
  .clk_i  ( clk               ),
  .cyc_i  ( wb_mem_cyc        ),
  .stb_i  ( wb_mem_stb        ),
  .we_i   ( wb_mem_we         ),
  .ack_o  ( wb_mem_ack        ),
  .be_i   ( wb_mem_be         ),
  .adr_i  ( wb_mem_adr[16:2]  ),
  .dat_i  ( wb_mem_wdat       ),
  .dat_o  ( wb_mem_rdat       )
);

fazyrv_top #( 
  .CHUNKSIZE  ( CHUNKSIZE ),
  .CONF       ( CONF      ),
  .MTVAL      ( MTVAL     ),
  .BOOTADR    ( BOOTADR   ),
  .RFTYPE     ( RFTYPE    ),
  .MEMDLY1    ( MEMDLY1   )
) i_fazyrv_core (
  .clk_i          ( clk          ),
  .rst_in         ( rst_n        ),

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

endmodule
