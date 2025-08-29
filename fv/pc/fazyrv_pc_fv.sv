// Copyright (c) 2025 Meinhard Kissich
// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
// File  :  fazyrv_pc_fv.sv
// Usage :  Formal test bench for fazyrv_pc.sv
//
// Ports
//  - clk_i           Clock input, sensitive to rising edge.
// -----------------------------------------------------------------------------

module fazyrv_pc_fv
(
  input logic clk_i
);

parameter CHUNKSIZE = 4;
parameter BOOTADR   = 32'hFFFF;

parameter NO_ICYC   = (32 / CHUNKSIZE);

logic                 inc;
logic                 shift;
logic [CHUNKSIZE-1:0] din;

logic [CHUNKSIZE-1:0] pc_ser;
logic [CHUNKSIZE-1:0] pc_ser_inc;
logic [31:0]          pc;


// --- formal only helpers ---

// Initial reset
logic fv_dly_reset_r = '1;
always_ff @(posedge clk_i) begin
  if (|fv_dly_reset_r) fv_dly_reset_r = fv_dly_reset_r - 'b1;
end

always_comb assume(rst_in == ~|fv_dly_reset_r);

// Counter to match FazyRV icyc
logic [$clog2(NO_ICYC+1)-1:0] fv_cycle_counter_r;
initial fv_cycle_counter_r = 'd0;

always_ff @(posedge clk_i) begin
  if (~rst_in)  fv_cycle_counter_r <= 'b0;
  else          fv_cycle_counter_r <= fv_cycle_counter_r + 'd1;
end

// First chunk
(* keep *) logic fv_cycle_lsb;
assign fv_cycle_lsb = (fv_cycle_counter_r == 0);

// Last chunk
(* keep *) logic fv_cycle_msb;
assign fv_cycle_msb = (fv_cycle_counter_r == NO_ICYC - 'd1);

// Cycle after last chunk; check state
logic fv_cycle_check = 'b0;
always_ff @(posedge clk_i) begin
  if (~rst_in)  fv_cycle_check <= 'b0;
  else          fv_cycle_check <= fv_cycle_msb;
end

// Remember shifted in data
//
logic [31:0] fv_din = 'b0;
always_ff @(posedge clk_i) fv_din <= {din, fv_din[31:CHUNKSIZE]};

logic [31:0] fv_pcinc = 'b0;
always_ff @(posedge clk_i) fv_pcinc <= {pc_ser_inc, fv_pcinc[31:CHUNKSIZE]};

logic [31:0] fv_pcser = 'b0;
always_ff @(posedge clk_i) fv_pcser <= {pc_ser, fv_pcser[31:CHUNKSIZE]};

logic fv_pc_op;
assign fv_pc_op = (fv_cycle_counter_r < NO_ICYC);

// --- Instances ---

fazyrv_pc #(
  .CHUNKSIZE  ( CHUNKSIZE ), 
  .BOOTADR    ( BOOTADR   )
) i_fazyrv_pc (
  .clk_i         ( clk_i              ),
  .rst_in        ( rst_in             ),
  // Continuous inc to strobe; handle here for simplicity
  .inc_i         ( inc & fv_cycle_lsb & fv_pc_op ),
  .shift_i       ( shift  & fv_pc_op  ),
  .din_i         ( din                ),
  .pc_ser_o      ( pc_ser             ), 
  .pc_ser_inc_o  ( pc_ser_inc         ),
  .pc_o          ( pc                 )
);


// --- General Assumptions ---
always_comb begin
  // No shifting in reset
  if (~rst_in) assume(~shift & ~inc);
  // Addition only when shifted out
  if (inc) assume(shift);
  // Assume normal pc increment
  if (inc) assume(din == pc_ser_inc);
  // Loading PC, assume data != 0 for easier debugging
  if (shift & ~inc) assume(din != 'b0);
end


// --- Stable cycle ---
always_ff @(posedge clk_i) begin
  if (~fv_cycle_check) begin
    assume (inc == $past(inc));
    assume (shift == $past(shift));

  end
end

// --- FV helpers & Asserts ---

logic [31:0] fv_prev_pc;

always_ff @(posedge clk_i) begin
  // Update helpers
  if (fv_cycle_check) begin
    fv_prev_pc <= pc;
  end

  // Assert Reset
  if ($rose(rst_in)) begin
    assert (pc == BOOTADR);
  end

  // -- End of cycle asserts --
  if (fv_cycle_check) begin
    // Inc
    if ($past(shift) & $past(inc)) begin
      assert (pc == fv_prev_pc + 'd4);
      assert (pc == fv_pcinc);
    end

    // Shift
    if ($past(shift)) begin
      assert (pc == fv_din);
    end

    // Nop
    if ($past(shift)) begin
      assert (fv_prev_pc == fv_pcser);
    end
  end
end

always_ff @(posedge clk_i) begin
  cover (rst_in);
  cover (rst_in & (pc == BOOTADR));
  cover (fv_cycle_check);
  cover (fv_cycle_check && $past(inc));
  cover (fv_cycle_check && $past(shift));
  cover (fv_cycle_check & (~inc & ~shift));
  cover (fv_cycle_check & (inc != $past(inc)));

  //
  cover ($past(shift) & $past(inc) & (pc == fv_prev_pc + 'd4));
  cover ($past(shift) & $past(inc) & (pc == fv_pcinc));
  cover ($past(shift) & (pc == fv_din));
  cover ($past(shift) & (fv_prev_pc == fv_pcser));
end

endmodule