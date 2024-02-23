// Copyright (c) 2023 - 2024 Meinhard Kissich
// -----------------------------------------------------------------------------
// File  :  fsoc_sim.sv
// Usage :  Simulation wrapper for the fsoc SoC.
// -----------------------------------------------------------------------------

`default_nettype none

module fsoc_sim #(
  parameter MEMFILE   = "",
  parameter MEMSIZE   = 8192,
  parameter CHUNKSIZE = 1,
  parameter RFTYPE    = "BRAM",
  parameter CONF      = "MIN",
  parameter MTVAL     = 'h0,
  parameter BOOTADR   = 'h1000
) (
  input  logic clk_i,
  input  logic rst_in,
  output logic q
);

localparam MEMDLY1  = 0;
localparam GPOCNT   = 3;

logic [1023:0] firmware_file;
initial
  if ($value$plusargs("firmware=%s", firmware_file)) begin
	  $display("Loading RAM from %0s", firmware_file);
	  $readmemh(firmware_file, i_fsoc.i_mem.mem_r);
  end

logic [GPOCNT-1:0] gpo;

assign q = gpo[0];

// gpo is used by embench to determine timing
logic [1023:0]      embench_file;
logic [GPOCNT-1:0]  gpo_r = '0;

real    start_time;
real    release_time;
integer f = 0;

initial begin
  $timeformat(-6, 0, "", 1);

  /* verilator lint_off WIDTH */
  if ($value$plusargs("embench=%s", embench_file)) begin
    $display("Writing embench_file timing to %0s", embench_file);
    f = $fopen(embench_file, "w");
  end
  /* verilator lint_on WIDTH */
end

logic rst_r = 'b0;
always @(posedge clk_i) begin
  rst_r <= rst_in;
  if (~rst_r & rst_in) begin
    release_time = $realtime;
  end
end

always @(posedge clk_i) begin
  gpo_r <= gpo;
  if ((~gpo_r[0] & gpo[0]) & (f != 0)) begin
    start_time = $realtime - release_time; 
    $display("Test started");
  end else if((gpo_r[0] & ~gpo[0]) & (f != 0)) begin
    $fwrite(f, "Bench time: %t\n", $realtime-start_time);
    $display("Test complete, waiting for validation");
  end

  if ((gpo[2] | gpo[1]) & (f != 0)) begin
    if (gpo[2]) begin
      $fwrite(f, "FAILED @ %t\n", $realtime-start_time);
      $display("FAILED");
      $finish;
    end else begin
      $fwrite(f, "SUCCESS @ %t\n", $realtime-start_time);
      $display("SUCCESS");
      $finish;
    end
  end
end


fsoc #( 
  .CHUNKSIZE  ( CHUNKSIZE ),
  .CONF       ( CONF      ),
  .RFTYPE     ( RFTYPE    ),
  .MTVAL      ( MTVAL     ),
  .BOOTADR    ( BOOTADR   ),
  .MEMFILE    ( MEMFILE   ),
  .MEMSIZE    ( MEMSIZE   ),
  .MEMDLY1    ( MEMDLY1   ),
  .GPOCNT     ( GPOCNT    )
) i_fsoc (
  .clk_i      ( clk_i   ),
  .rst_in     ( rst_in  ),
  //.tirq_i     ( 1'b0    ),
  //.trap_o     ( ),
  .gpi_i      ( 1'b0    ),
  .gpo_o      ( gpo     )
);


logic [63:0] mcycle_r;

// --- Cylce counter ---
always @(posedge clk_i) begin
  if (~rst_in) begin
    mcycle_r = 'b0;
  end else begin
    mcycle_r = mcycle_r + 'b1;
  end 
end

// --- Instr to ASCII ---
/* verilator lint_off WIDTHEXPAND */
logic [128:0] dbg_ascii_instr;

//                         30    25    20    15    10     5     0
//                          |     |     |     |     |     |     |
`define INSTR_LUI     (32'b??_?????_?????_?????_?????_???01_10111)
`define INSTR_AUIPC   (32'b??_?????_?????_?????_?????_???00_10111)
`define INSTR_JAL     (32'b??_?????_?????_?????_?????_???11_01111)
`define INSTR_JALR    (32'b??_?????_?????_?????_000??_???11_00111)
`define INSTR_BEQ     (32'b??_?????_?????_?????_000??_???11_00011)
`define INSTR_BNE     (32'b??_?????_?????_?????_001??_???11_00011)
`define INSTR_BLT     (32'b??_?????_?????_?????_100??_???11_00011)
`define INSTR_BGE     (32'b??_?????_?????_?????_101??_???11_00011)
`define INSTR_BLTU    (32'b??_?????_?????_?????_110??_???11_00011)
`define INSTR_BGEU    (32'b??_?????_?????_?????_111??_???11_00011)
`define INSTR_LB      (32'b??_?????_?????_?????_000??_???00_00011)
`define INSTR_LH      (32'b??_?????_?????_?????_001??_???00_00011)
`define INSTR_LW      (32'b??_?????_?????_?????_010??_???00_00011)
`define INSTR_LBU     (32'b??_?????_?????_?????_100??_???00_00011)
`define INSTR_LHU     (32'b??_?????_?????_?????_101??_???00_00011)
`define INSTR_SB      (32'b??_?????_?????_?????_000??_???01_00011)
`define INSTR_SH      (32'b??_?????_?????_?????_001??_???01_00011)
`define INSTR_SW      (32'b??_?????_?????_?????_010??_???01_00011)
`define INSTR_ADDI    (32'b??_?????_?????_?????_000??_???00_10011)
`define INSTR_SLTI    (32'b??_?????_?????_?????_010??_???00_10011)
`define INSTR_SLTIU   (32'b??_?????_?????_?????_011??_???00_10011)
`define INSTR_XORI    (32'b??_?????_?????_?????_100??_???00_10011)
`define INSTR_ORI     (32'b??_?????_?????_?????_110??_???00_10011)
`define INSTR_ANDI    (32'b??_?????_?????_?????_111??_???00_10011)
`define INSTR_SLLI    (32'b00_00000_?????_?????_001??_???00_10011)
`define INSTR_SRLI    (32'b00_00000_?????_?????_101??_???00_10011)
`define INSTR_SRAI    (32'b01_00000_?????_?????_101??_???00_10011)
`define INSTR_ADD     (32'b00_00000_?????_?????_000??_???01_10011)
`define INSTR_SUB     (32'b01_00000_?????_?????_000??_???01_10011)
`define INSTR_SLL     (32'b00_00000_?????_?????_001??_???01_10011)
`define INSTR_SLT     (32'b00_00000_?????_?????_010??_???01_10011)
`define INSTR_SLTU    (32'b00_00000_?????_?????_011??_???01_10011)
`define INSTR_XOR     (32'b00_00000_?????_?????_100??_???01_10011)
`define INSTR_SRL     (32'b00_00000_?????_?????_101??_???01_10011)
`define INSTR_SRA     (32'b01_00000_?????_?????_101??_???01_10011)
`define INSTR_OR      (32'b00_00000_?????_?????_110??_???01_10011)
`define INSTR_AND     (32'b00_00000_?????_?????_111??_???01_10011)
`define INSTR_ECALL   (32'b??_0????_????0_?????_000??_???11_10011)
`define INSTR_EBREAK  (32'b??_0????_????1_?????_000??_???11_10011)
`define INSTR_CSRRW   (32'b??_?????_?????_?????_001??_???11_10011)
`define INSTR_CSRRS   (32'b??_?????_?????_?????_010??_???11_10011)
`define INSTR_CSRRC   (32'b??_?????_?????_?????_011??_???11_10011)
`define INSTR_CSRRWI  (32'b??_?????_?????_?????_101??_???11_10011)
`define INSTR_CSRRSI  (32'b??_?????_?????_?????_110??_???11_10011)
`define INSTR_CSRRCI  (32'b??_?????_?????_?????_111??_???11_10011)
`define INSTR_MRET    (32'b??_1????_?????_?????_000??_???11_10011)

always_comb begin
  casez(i_fsoc.i_fazyrv_core.wb_imem_dat_i)
    `INSTR_LUI:     dbg_ascii_instr = "lui";
    `INSTR_AUIPC:   dbg_ascii_instr = "auipc";
    `INSTR_JAL:     dbg_ascii_instr = "jal";
    `INSTR_JALR:    dbg_ascii_instr = "jalr";
    `INSTR_BEQ:     dbg_ascii_instr = "beq";
    `INSTR_BNE:     dbg_ascii_instr = "bne";
    `INSTR_BLT:     dbg_ascii_instr = "blt";
    `INSTR_BGE:     dbg_ascii_instr = "bge";
    `INSTR_BLTU:    dbg_ascii_instr = "bltu";
    `INSTR_BGEU:    dbg_ascii_instr = "bgeu";
    `INSTR_BEQ:     dbg_ascii_instr = "beq";
    `INSTR_BNE:     dbg_ascii_instr = "bne";
    `INSTR_BLT:     dbg_ascii_instr = "blt";
    `INSTR_BGE:     dbg_ascii_instr = "bge";
    `INSTR_BLTU:    dbg_ascii_instr = "bltu";
    `INSTR_BGEU:    dbg_ascii_instr = "bgeu";
    `INSTR_LB:      dbg_ascii_instr = "lb";
    `INSTR_LH:      dbg_ascii_instr = "lh";
    `INSTR_LW:      dbg_ascii_instr = "lw";
    `INSTR_LBU:     dbg_ascii_instr = "lbu";
    `INSTR_LHU:     dbg_ascii_instr = "lhu";
    `INSTR_SB:      dbg_ascii_instr = "sb";
    `INSTR_SH:      dbg_ascii_instr = "sh";
    `INSTR_SW:      dbg_ascii_instr = "sw";
    `INSTR_ADDI:    dbg_ascii_instr = "addi";
    `INSTR_SLTI:    dbg_ascii_instr = "slti";
    `INSTR_SLTIU:   dbg_ascii_instr = "sltiu";
    `INSTR_XORI:    dbg_ascii_instr = "xori";
    `INSTR_ORI:     dbg_ascii_instr = "ori";
    `INSTR_ANDI:    dbg_ascii_instr = "andi";
    `INSTR_SLLI:    dbg_ascii_instr = "slli";
    `INSTR_SRLI:    dbg_ascii_instr = "srli";
    `INSTR_SRAI:    dbg_ascii_instr = "srai";
    `INSTR_ADD:     dbg_ascii_instr = "add";
    `INSTR_SUB:     dbg_ascii_instr = "sub";
    `INSTR_SLL:     dbg_ascii_instr = "sll";
    `INSTR_SLT:     dbg_ascii_instr = "slt";
    `INSTR_SLTU:    dbg_ascii_instr = "sltu";
    `INSTR_XOR:     dbg_ascii_instr = "xor";
    `INSTR_SRL:     dbg_ascii_instr = "srl";
    `INSTR_SRA:     dbg_ascii_instr = "sra";
    `INSTR_OR:      dbg_ascii_instr = "or";
    `INSTR_AND:     dbg_ascii_instr = "and";
    `INSTR_CSRRW:   dbg_ascii_instr = "csrrw";
    `INSTR_CSRRS:   dbg_ascii_instr = "csrrs";
    `INSTR_CSRRC:   dbg_ascii_instr = "csrrc";
    `INSTR_CSRRW:   dbg_ascii_instr = "csrrw";
    `INSTR_CSRRS:   dbg_ascii_instr = "csrrs";
    `INSTR_CSRRC:   dbg_ascii_instr = "csrrc";
    `INSTR_CSRRWI:  dbg_ascii_instr = "csrrwi";
    `INSTR_CSRRSI:  dbg_ascii_instr = "csrrsi";
    `INSTR_CSRRCI:  dbg_ascii_instr = "csrrci";
    `INSTR_ECALL:   dbg_ascii_instr = "ecall";
    `INSTR_EBREAK:  dbg_ascii_instr = "ebreak";
    `INSTR_MRET:    dbg_ascii_instr = "mret";
    default:        dbg_ascii_instr = "illegal";
  endcase
end
/* verilator lint_on WIDTHEXPAND */

logic [1023:0] timing_file;
integer f_timing = 0;
logic q_r;

initial begin
  if ($value$plusargs("timing=%s", timing_file)) begin
    f_timing = $fopen(timing_file, "w");
  end
end

always_ff @(posedge clk_i) begin
  q_r <= q;
end

(* keep *) logic dly_stb;
always_ff @(posedge clk_i) begin
  dly_stb <= i_fsoc.i_fazyrv_core.wb_imem_stb_o;
end

(* keep *) logic fwrite_stb;

generate
if (MEMDLY1 == 1) begin
  assign fwrite_stb = dly_stb;
end else begin
  assign fwrite_stb = i_fsoc.i_fazyrv_core.wb_imem_stb_o & i_fsoc.i_fazyrv_core.wb_imem_ack_i;
end

endgenerate

always @(posedge clk_i) begin
  if ((f_timing != 0) && (q | q_r)) begin
    if (fwrite_stb) begin
      $fwrite(f_timing, "## %-s %d\n", dbg_ascii_instr, mcycle_r);
    end
  end

  if (q_r & ~q) begin
    $fclose(f_timing);
    f_timing = 0;
  end
end

endmodule
