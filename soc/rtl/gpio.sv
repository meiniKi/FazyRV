
module gpio #( parameter GPOCNT = 1 ) (
  input  logic                clk_i,
  input  logic                cyc_i,
  input  logic                stb_i,
  input  logic                we_i,
  output logic                ack_o,
  input  logic [3:0]          be_i,
  input  logic [31:0]         dat_i,
  output logic [31:0]         dat_o,
  input  logic                gpi_i,
  output logic [GPOCNT-1:0]  gpo_o
);

logic [GPOCNT-1:0] gpo_r;

assign ack_o = cyc_i & stb_i;
assign dat_o = {31'b0, gpi_i};
assign gpo_o = gpo_r;

always @(posedge clk_i) begin
   if (cyc_i & stb_i & we_i & be_i[0]) begin
      gpo_r <= dat_i[GPOCNT-1:0];
      //if (be_i[0]) gpo_r[7:0]   <= dat_i[7:0];
      //if (be_i[1]) gpo_r[15:8]  <= dat_i[15:8];
      //if (be_i[2]) gpo_r[23:16] <= dat_i[23:16];
      //if (be_i[3]) gpo_r[31:24] <= dat_i[31:24];
   end
end

endmodule