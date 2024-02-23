// Copyright (c) 2023 - 2024 Meinhard Kissich
// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
// File  :  fazyrv_spm_d_fv.sv
// Usage :  Formal test bench for fazyrv_spm_d.sv 
// Ports
//  - clk_i     Clock input.
// -----------------------------------------------------------------------------

module fazyrv_spm_d_fv (
  input logic clk_i
);

parameter CHUNKSIZE = 8;
parameter NO_ICYC = (32 / CHUNKSIZE);

logic                 ld_par;
logic [4:0]           shamt;

logic                 lsb;
logic                 msb;
logic                 shft_op;

logic                 sext;
logic                 lb_op;
logic                 lh_op;
logic                 lw_op;
logic                 sb_op;
logic                 sh_op;
logic                 sw_op;
logic                 cyc_wt;
logic                 cyc_shft;
logic                 done;
logic                 left;
logic                 arith;
logic [CHUNKSIZE-1:0] ser_inp;
logic [CHUNKSIZE-1:0] ser_out;
logic [1:0]           adr_lsbs;

logic [31:0]          pdin;
logic [31:0]          pdout;

logic                 cyc_rd;


logic [$clog2(NO_ICYC)-1:0] cyc_r, cyc_n;

enum int unsigned {INIT=0, OP_LB, OP_LH, OP_LW, OP_SR, OP_SL, OP_SRL, PRE_PAR, PRE_SER, POST_RD, CHECK} state_r, state_n, fv_state_tst_r;


(* keep *) logic [63:0] dbg_state_ascii = "";

always_comb begin
  case (state_r)
    INIT:     dbg_state_ascii = "init";
    OP_LB:    dbg_state_ascii = "lb";
    OP_LH:    dbg_state_ascii = "lh";
    OP_LW:    dbg_state_ascii = "lw";
    OP_SR:    dbg_state_ascii = "sr";
    OP_SL:    dbg_state_ascii = "sl";
    OP_SRL:   dbg_state_ascii = "srl";
    PRE_PAR:  dbg_state_ascii = "par";
    PRE_SER:  dbg_state_ascii = "ser";
    POST_RD:  dbg_state_ascii = "rd";
    CHECK:    dbg_state_ascii = "check";
    default:  dbg_state_ascii = "illegal";
  endcase
end

initial begin
  assume (state_r == INIT);
end

(* anyconst *) int unsigned fv_op;

// ---- ensure alignment ---
always_comb assume ( (fv_op != OP_LH) | (fv_tst_adr_lsbs_r[0] == 1'b0));
always_comb assume ( (fv_op != OP_LW) | (fv_tst_adr_lsbs_r[1:0] == 2'b0));


//always_comb assume (shamt == 'd8);
//always_comb assume ((adr_lsbs == 2'b10));
always_comb assume ((fv_op == OP_LB)|(fv_op == OP_LH)|(fv_op == OP_LW)|(fv_op == OP_SR)|(fv_op == OP_SL)|(fv_op == OP_SRL));
//always_comb assume ((fv_op == OP_LW));
//always_comb assume (fv_tst_shamt == 'd16);
//always_comb assume (fv_tst_val == 'h00_00_00_28);

// --- random sequences, change any cycle ---
(* anyseq *) logic [31:0] fv_tst_val;
(* anyseq *) logic [4:0]  fv_tst_shamt;
(* anyseq *) logic        fv_tst_sign;
(* anyseq *) logic [1:0]  fv_tst_adr_lsbs;

// --- drawn values for that cycle ---
logic [31:0]  fv_tst_val_r, fv_tst_val_ref;
logic [4:0]   fv_tst_shamt_r;
logic         fv_tst_sign_r;
logic [1:0]   fv_tst_adr_lsbs_r;

(* keep *) logic [31:0]  fv_check_tmp;

logic lsb_r;
logic cyc_done;

assign cyc_done = (cyc_r == '1);

always_ff @(posedge clk_i) begin
  lsb_r <= msb;
end

// --- control signals ---
assign lsb      = lsb_r;

assign sext     = (state_r != INIT) & fv_tst_sign_r & (fv_op != OP_SL) & (fv_op != OP_SR);

assign lb_op    = (state_r != INIT) & (fv_op == OP_LB);
assign lh_op    = (state_r != INIT) & (fv_op == OP_LH);
assign lw_op    = (state_r != INIT) & (fv_op == OP_LW);

assign sb_op    = 1'b0;
assign sh_op    = 1'b0;
assign sw_op    = 1'b0;

assign left     = (state_r != INIT) & (fv_op == OP_SL);
assign arith    = (state_r != INIT) & ((fv_op == OP_SRL)) ;
assign shft_op  = (state_r != INIT) & ((fv_op == OP_SL)|(fv_op == OP_SRL)|(fv_op == OP_SR));

// --- data, feedback, addr ---
assign ser_inp  = cyc_shft ? ser_out : fv_tst_val_r[CHUNKSIZE-1:0];
assign pdin     = fv_tst_val_r;
assign adr_lsbs = fv_tst_adr_lsbs_r;


always_comb begin
  cyc_wt    = 1'b0;
  // in cpu only stable at WT cylce, but at load directly.
  shamt     = ((fv_op == OP_LB) | (fv_op == OP_LH) | (fv_op == OP_LW)) ? fv_tst_shamt_r : 4'b0; 
  cyc_n     = cyc_r + 'b1;
  state_n   = state_r;

  ld_par    = 1'b0;
  cyc_rd    = 1'b0;
  cyc_shft  = 1'b0;
  msb       = 1'b0;

  fv_check_tmp  = 'b0;

  case (state_r)
    INIT: begin
      state_n = ((fv_op == OP_LB) | (fv_op == OP_LH) | (fv_op == OP_LW)) ? PRE_PAR : PRE_SER;
      cyc_n   = 'b0;
      msb     = 1'b1;
    end

    // Load parallel from simulated memory
    PRE_PAR: begin
      cyc_n   = 'b0;
      ld_par  = 1'b1;
      cyc_wt  = 1'b1;
      state_n = fv_state_tst_r;
      msb     = 1'b1;
      if (done) begin
        state_n = POST_RD;
      end 
    end

    // Load serial from registers, etc
    PRE_SER: begin
      if (cyc_done) begin
        cyc_n   = 'b0;
        shamt     = fv_tst_shamt_r;
        if (done) begin
          // there is no macro step, go to read out
          state_n = POST_RD;
          msb     = 1'b1;
        end else begin
          // wait for macro steps to be done
          state_n = fv_state_tst_r;
        end
      end
    end

    // 
    OP_LB, OP_LH, OP_LW: begin
      cyc_n    = 'b0;
      cyc_shft = 1'b1;
      if (done) begin
        msb     = 1'b1;
        state_n = POST_RD;
      end  
      
    end

    //
    OP_SR, OP_SL, OP_SRL: begin
      cyc_shft  = 1'b1;
      cyc_n     = 'b0;
      shamt     = fv_tst_shamt_r;
      if (done) begin
        msb     = 1'b1;
        state_n = POST_RD;
      end 
    end


    POST_RD: begin
      shamt     = fv_tst_shamt_r;
      cyc_rd    = 1'b1;
      if (cyc_done) begin
        msb     = 1'b1;
        state_n = CHECK;
      end
    end

    CHECK: begin
      state_n       = INIT;
      if (fv_state_tst_r == OP_LB) begin
        fv_check_tmp = ((fv_tst_val_ref >> (8*fv_tst_adr_lsbs_r)) & 'h00_00_00_FF);
        if (fv_tst_sign_r)  assert (fv_tst_val_r == (fv_check_tmp | {{24{fv_check_tmp[7]}}, 8'b0} ));
        else                assert (fv_tst_val_r == fv_check_tmp);
      end
      if (fv_state_tst_r == OP_LH) begin
        fv_check_tmp = ((fv_tst_val_ref >> (16*fv_tst_adr_lsbs_r[1])) & 'h00_00_FF_FF);
        if (fv_tst_sign_r)  assert (fv_tst_val_r == (fv_check_tmp| {{16{fv_check_tmp[15]}}, 16'b0} ));
        else                assert (fv_tst_val_r == fv_check_tmp);
      end
      if (fv_state_tst_r == OP_LW) begin
        fv_check_tmp = (fv_tst_val_ref);
        assert (fv_tst_val_r == fv_check_tmp);
      end
      if (fv_state_tst_r == OP_SR) begin
        assert (fv_tst_val_r == (fv_tst_val_ref >> fv_tst_shamt_r));
      end
      if (fv_state_tst_r == OP_SL) begin
        fv_check_tmp = (fv_tst_val_ref << fv_tst_shamt_r);
        assert (fv_tst_val_r == fv_check_tmp);
      end
      if (fv_state_tst_r == OP_SRL) begin
        assert ($signed(fv_tst_val_r) == ($signed(fv_tst_val_ref) >>> fv_tst_shamt_r));
      end
    end
  endcase
end

// Some covers
always_comb begin

  cover (state_r == PRE_PAR);
  // LB
  cover ((state_r == OP_LB));
  cover ((state_r == CHECK) && (fv_state_tst_r == OP_LB) && ~fv_tst_sign_r && (fv_tst_val_r == (fv_tst_val_ref & 'h00_00_00_FF)));
  cover ((state_r == CHECK) && (fv_state_tst_r == OP_LB) && fv_tst_sign_r && (fv_tst_val_r == ((fv_tst_val_ref & 'h00_00_00_FF) | {{24{fv_tst_val_ref[7]}}, 8'b0} )));
  //
  // LH
  cover ((state_r == OP_LH));
  cover ((state_r == CHECK) && (fv_state_tst_r == OP_LH) && ~fv_tst_sign_r && (fv_tst_val_r == (fv_tst_val_ref & 'h00_00_FF_FF)));
  cover ((state_r == CHECK) && (fv_state_tst_r == OP_LH) && fv_tst_sign_r && (fv_tst_val_r == ((fv_tst_val_ref & 'h00_00_FF_FF) | {{16{fv_tst_val_ref[15]}}, 16'b0} )));
  //
  // LW
  cover ((state_r == CHECK));
  cover ((state_r == CHECK) && (fv_state_tst_r == OP_LW) && (fv_tst_val_r == fv_tst_val_ref));
  //
  // SR
  cover (state_r == POST_RD);
  cover ((state_r == CHECK) && (fv_state_tst_r == OP_SR) && (fv_tst_val_r == (fv_tst_val_ref >> fv_tst_shamt_r)));
  //
  // SL
  cover (state_r == POST_RD);
  cover ((state_r == CHECK) && (fv_state_tst_r == OP_SL) && (fv_tst_val_r == (fv_tst_val_ref << fv_tst_shamt_r)));
  //
  // SRL
  cover ((state_r == CHECK) && (fv_state_tst_r == OP_SRL) && (fv_tst_val_r == (fv_tst_val_ref >>> fv_tst_shamt_r)));
end


always_ff @(posedge clk_i) begin
  cyc_r   <= cyc_n;
  state_r <= state_n;

  fv_tst_val_r <= {ser_out, fv_tst_val_r[31 -: (32-CHUNKSIZE)]};

  // Take samples
  if (state_r == INIT) begin
    fv_tst_val_r      <= fv_tst_val;
    fv_tst_val_ref    <= fv_tst_val;
    fv_tst_shamt_r    <= fv_tst_shamt;
    fv_tst_sign_r     <= fv_tst_sign;
    fv_state_tst_r    <= fv_op;
    fv_tst_adr_lsbs_r <= fv_tst_adr_lsbs; 
  end
end

fazyrv_spm_d #(.CHUNKSIZE(CHUNKSIZE)) i_fazyrv_spm_d
(
  .clk_i        ( clk_i             ),
  .ld_par_i     ( ld_par            ),
  .adr_lsbs_i   ( adr_lsbs          ),

  .instr_ld_i   ( lb_op|lh_op|lw_op ),
  .instr_st_i   ( sb_op|sh_op|sw_op ),
  .ls_b_i       ( lb_op|sb_op       ),
  .ls_h_i       ( lh_op|sh_op       ),
  .ls_w_i       ( lw_op|sw_op       ),

  .arith_i      ( arith | sext      ),
  .shft_op_i    ( shft_op           ),
  .left_i       ( left              ),
  .shamt_i      ( shamt             ),
  .done_o       ( done              ),
  .icyc_i       ( cyc_r             ),
  .icyc_lsb_i   ( lsb               ),
  .icyc_msb_i   ( msb               ),
  .cyc_rd_i     ( cyc_rd            ),
  .cyc_wt_i     ( cyc_wt            ),
  .cyc_shft_i   ( cyc_shft          ),
  .ser_i        ( ser_inp           ),
  .ser_o        ( ser_out           ),
  .ser_pc_o     ( ),
  .misalngd_o   ( ),
  .pdin_i       ( pdin              ),
  .pdout_o      ( pdout             )
);



endmodule