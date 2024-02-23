// Copyright (c) 2023 - 2024 Meinhard Kissich
// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
// File  :  fazyrv_alu_fv.sv
// Usage :  Formal test bench for fazyrv_alu.sv
//
// Ports
//  - clk_i           Clock input, sensitive to rising edge.
// -----------------------------------------------------------------------------

module fazyrv_alu_fv
(
  input logic clk_i
);

parameter CHUNKSIZE   = 8;
parameter ITERATIONS  = 32 / CHUNKSIZE; 

enum int unsigned { INIT, OPERATE } state_r, state_n;
enum int unsigned { OP_PASS=0, OP_ADD, OP_SUB, OP_LT, OP_LTU, OP_EQ, OP_XOR, OP_OR, OP_AND } op;

(* anyseq *) logic [31:0] rs_a_32_seq;
(* anyseq *) logic [31:0] rs_b_32_seq;
(* anyseq *) logic [31:0] op_seq;

// Constraint op
always_comb assume (op_seq <= OP_AND);

logic [31:0] rs_a_32_r;
logic [31:0] rs_b_32_r;
logic [31:0] rd_32_r;

logic [$clog2(ITERATIONS)-1:0] it_cnter_r, it_cnter_n;
logic lsb, msb;

// logic that connects to the alu (possibly smaller bit width)
logic [CHUNKSIZE-1:0] rs_a;
logic [CHUNKSIZE-1:0] rs_b;
logic [CHUNKSIZE-1:0] rd;
logic cmp;

// alu control signals
logic sel_arith;
logic en_a_i;
logic op_sub;
logic op_xor;
logic op_and;
logic cmp_signd;
logic cmp_eq;
logic cmp_keep_i;

// --- formal only helpers ---
logic [2:0] fv_cycle_counter_r, fv_cycle_counter_n;
initial fv_cycle_counter_r = 'd0;

logic fv_cycle_done;

// --- Instances ---

fazyrv_alu #( .CHUNKSIZE(CHUNKSIZE) ) i_fazyr_alu
(
  .clk_i        ( clk_i     ),
  .lsb_i        ( lsb       ),
  .msb_i        ( msb       ),
  .rs_a_i       ( rs_a      ),
  .rs_b_i       ( rs_b      ),
  .res_o        ( rd        ),
  .cmp_o        ( cmp       ),
  .sel_arith_i  ( sel_arith ),
  .en_a_i       ( en_a_i    ),
  .op_sub_i     ( op_sub    ),
  .op_xor_i     ( op_xor    ),     
  .op_and_i     ( op_and    ),
  .cmp_signd_i  ( cmp_signd ),
  .cmp_keep_i   ( 1'b0      ),
  .cmp_eq_i     ( cmp_eq    )
);

// --- Decoder ---

always_comb begin
  sel_arith = 1'b0;
  en_a_i    = 1'b0;
  op_sub    = 1'b0;
  op_xor    = 1'b0;
  op_and    = 1'b0;
  cmp_signd = 1'b0;
  cmp_eq    = 1'b0;

  case (op)
    OP_PASS: begin
      sel_arith = 1'b1;
    end

    OP_ADD: begin
      sel_arith = 1'b1;
      en_a_i    = 1'b1;
    end 

    OP_SUB: begin
      op_sub    = 1'b1;
      sel_arith = 1'b1;
      en_a_i    = 1'b1; 
    end

    OP_LT: begin
      en_a_i    = 1'b1;
      cmp_signd = 1'b1;
    end
    
    OP_LTU: begin
      en_a_i    = 1'b1;
    end

    OP_EQ: begin
      en_a_i    = 1'b1;
      cmp_eq    = 1'b1;
    end

    OP_XOR: begin  
      en_a_i    = 1'b1;
      op_xor    = 1'b1;
    end

    OP_OR: begin
      en_a_i    = 1'b1;
    end

    OP_AND: begin
      en_a_i    = 1'b1;
      op_and    = 1'b1;
    end
  endcase
end

// --- Clock and Init ---

/*
logic clk_r;
always @($global_clock) begin
	assume(clk_i == !clk_r);
	clk_r <= clk_i;
end
*/

initial state_r = INIT;

always_ff @(posedge clk_i) begin
  state_r <= state_n;
end

// --- Apply and Capture ---

assign rs_a = rs_a_32_r [0 +: CHUNKSIZE];
assign rs_b = rs_b_32_r [0 +: CHUNKSIZE];

// results need to be there one cycle earlier for checking
// thus, take this composition instead of registered value
logic [31:0] fv_rs_a;
logic [31:0] fv_rs_b;
logic [31:0] fv_rd;

generate;
  if (CHUNKSIZE < 32) begin
    assign fv_rs_a  = {rs_a, rs_a_32_r[31:CHUNKSIZE]};
    assign fv_rs_b  = {rs_b, rs_b_32_r[31:CHUNKSIZE]};
    assign fv_rd    = {rd, rd_32_r[31:CHUNKSIZE]};
  end else begin
    assign fv_rs_a  = rs_a;
    assign fv_rs_b  = rs_b;
    assign fv_rd    = rd;
  end
endgenerate


always_ff @(posedge clk_i) begin
  rs_a_32_r  <= rs_a_32_r;
  rs_b_32_r  <= rs_b_32_r;
  it_cnter_r <= it_cnter_n;

  case(state_r)
    INIT: begin
      rs_a_32_r <= rs_a_32_seq;
      rs_b_32_r <= rs_b_32_seq;
      op        <= op_seq;
    end

    OPERATE: begin
      if (it_cnter_r != 'd0) begin
        rs_a_32_r <= {rs_a, rs_a_32_r[31:CHUNKSIZE]};
        rs_b_32_r <= {rs_b, rs_b_32_r[31:CHUNKSIZE]};
        rd_32_r   <= {rd, rd_32_r[31:CHUNKSIZE]};
        op        <= op; 
      end else begin
        rs_a_32_r <= rs_a_32_seq;
        rs_b_32_r <= rs_b_32_seq;
        op        <= op_seq;

        // Check
        if (op == OP_PASS) assert ( fv_rd == fv_rs_b );
        if (op == OP_ADD)  assert ( fv_rd == (fv_rs_a + fv_rs_b) );
        if (op == OP_SUB)  assert ( fv_rd == (fv_rs_a - fv_rs_b) );
        if (op == OP_LT)   assert ( cmp == ($signed(fv_rs_a) < $signed(fv_rs_b)) );
        if (op == OP_LTU)  assert ( cmp == (fv_rs_a < fv_rs_b) );
        if (op == OP_EQ)   assert ( cmp == (fv_rs_a == fv_rs_b) );
        if (op == OP_XOR)  assert ( fv_rd == (fv_rs_a ^ fv_rs_b) );
        if (op == OP_OR)   assert ( fv_rd == (fv_rs_a | fv_rs_b) );
        if (op == OP_AND)  assert ( fv_rd == (fv_rs_a & fv_rs_b) );

      end    
    end
  endcase
end


// --- Next State and Output ---

always_comb begin: state_logic
  state_n       = state_r;
  msb           = 1'b0;
  lsb           = 1'b0;
  it_cnter_n    = it_cnter_r;
  fv_cycle_done = 1'b0;

  case(state_r)
    INIT: begin
      state_n     = OPERATE;
      it_cnter_n  = ITERATIONS - 'd1;
      msb         = 1'b1;

      // In case we are straight going into the second cylce
      //if(it_cnter_n == 'd0) begin
      //  msb         = 1'b1;
      //  it_cnter_n  = ITERATIONS - 'd1;
      //end
    end

    OPERATE: begin
      state_n     = OPERATE;
      it_cnter_n  = it_cnter_r - 'd1;

      if(it_cnter_r == (ITERATIONS - 'd1)) begin
        lsb         = 1'b1;
      end

      if(it_cnter_r == 'd0) begin
        it_cnter_n  = ITERATIONS - 'd1;
        msb         = 1'b1;

        fv_cycle_done = 1'b1;
      end
    end

    default: state_n = INIT;
  endcase
end

// --- FV helpers ---

assign fv_cycle_counter_n = ((state_r == OPERATE) && (it_cnter_r == 'd0)) ? fv_cycle_counter_r+'d1 : fv_cycle_counter_r;

always_ff @(posedge clk_i) begin
  fv_cycle_counter_r <= fv_cycle_counter_n;
end



// --- Cover ---
//always @(posedge clk_i) begin
//  cover((state_r == CHECK) && (op == OP_PASS));
//end

always_comb begin

  cover (fv_cycle_done & (op == OP_PASS));
  cover (fv_cycle_done & (op == OP_ADD));
  cover (fv_cycle_done & (op == OP_SUB));
  cover (fv_cycle_done & (op == OP_LT));
  cover (fv_cycle_done & (op == OP_LTU));
  cover (fv_cycle_done & (op == OP_EQ));
  cover (fv_cycle_done & (op == OP_XOR));
  cover (fv_cycle_done & (op == OP_OR));
  cover (fv_cycle_done & (op == OP_AND));

  cover (fv_cycle_counter_r == 'd1);

  // for debugging
  //assume (op == OP_PASS);
  //assume ($signed(rs_a_32_seq) < $signed('d5));
  //assume ($signed(rs_b_32_seq) < $signed('d5));
  //assume (rs_a_32_seq < 'd5);
  //assume (rs_b_32_seq < 'd5);
end

endmodule