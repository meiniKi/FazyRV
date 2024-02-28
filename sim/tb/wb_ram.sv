// Copyright (c) 2023 - 2024 Meinhard Kissich
// -----------------------------------------------------------------------------
// File  :  wb_ram.sv
// Usage :  Simple Wishbone RAM for executing riscvtests.
// -----------------------------------------------------------------------------

module wb_ram #(parameter depth=256, parameter memfile="")
(
   input  logic                     clk_i,
   input  logic                     cyc_i,
   input  logic                     stb_i,
   input  logic                     we_i,
   output logic                     ack_o,
   input  logic [3:0]               be_i,
   input  logic [$clog2(depth)-1:0] adr_i,
   input  logic [31:0]              dat_i,
   output logic [31:0]              dat_o

);

localparam LATENCY = 1; // 0 or 1

logic [31:0] mem_r [0:depth-1];

generate
   if (LATENCY == 0) begin
      assign ack_o = cyc_i & stb_i;
      assign dat_o = mem_r[adr_i]; 
   end else begin
      
      always @(posedge clk_i) begin
         ack_o <= 'b0;
         if (cyc_i & stb_i) begin
            dat_o <= mem_r[adr_i];
            ack_o <= ~ack_o;
         end
      end
   end
endgenerate

always @(posedge clk_i) begin
   if (cyc_i & stb_i & we_i) begin
      if (be_i[0]) mem_r[adr_i][7:0]   <= dat_i[7:0];
      if (be_i[1]) mem_r[adr_i][15:8]  <= dat_i[15:8];
      if (be_i[2]) mem_r[adr_i][23:16] <= dat_i[23:16];
      if (be_i[3]) mem_r[adr_i][31:24] <= dat_i[31:24];
   end
end

initial begin
	if(memfile != "") begin
	   $display("Preloading %m from %s", memfile);
	   $readmemh(memfile, mem_r);
	end
end

endmodule