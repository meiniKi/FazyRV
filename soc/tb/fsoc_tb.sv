// Copyright (c) 2023 - 2024 Meinhard Kissich
// -----------------------------------------------------------------------------
// File  :  fsoc_tb.sv
// Usage :  Testbench for the fsoc SoC.
// -----------------------------------------------------------------------------

`default_nettype none

module fsoc_tb #(
  parameter MEMFILE   = "",
  parameter MEMSIZE   = 8192,
  parameter CHUNKSIZE = 1,
  parameter RFTYPE    = "BRAM",
  parameter CONF      = "MIN",
  parameter MTVAL     = 'h0,
  parameter BOOTADR   = 'h0
);

logic clk     = 1'b0;
logic rst_n   = 1'b0;

always #5 clk = ~clk;

initial begin
  rst_n <= 1'b0;
  repeat (100) @(posedge clk);
  rst_n <= 1;
end

fsoc #( 
  .CHUNKSIZE  ( CHUNKSIZE ),
  .CONF       ( CONF      ),
  .RFTYPE     ( RFTYPE    ),
  .MTVAL      ( MTVAL     ),
  .BOOTADR    ( BOOTADR   ),
  .MEMFILE    ( MEMFILE   ),
  .MEMSIZE    ( MEMSIZE   )
) i_fsoc (
  .clk_i    ( clk       ),
  .rst_in   ( rst_n     ),
  .tirq_i   ( 1'b0      ),
  .trap_o   ( ),
  .gpi_i    ( 1'b0      ),
  .gpo_o    ( )
);

initial begin
  if ($test$plusargs("vcd")) begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
  end
  repeat (600000) @(posedge clk);
  $display("TIMEOUT");
  $finish;
end

endmodule
