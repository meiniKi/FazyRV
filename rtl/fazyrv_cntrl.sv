// Copyright (c) 2023 Meinhard Kissich
// -----------------------------------------------------------------------------
// File  :  fazyrv_cntrl.sv
// Usage :  Control state machine for the core. It splits the instructions
//          into its parts and leads to the serial processing of data words.
//
// Param
//  - BWIDTH            Data path width of the core.
//  - RF_TYPE           RAM type used for register file.
//  - CYCLES_PER_INSTR  Cylces per instructions (part)..
//
// Ports
//  - clk_i           Clock input, sensitive to rising edge.
//  - rst_in          Reset, low active.
//  - abort_i         Abort after ICYC1 and go back to fetch.
//  - pc_noinc_i      Suppress PC increment.
//  - lsb_o           High iff LSB of data is processed at next clk cycle.
//  - msb_o           High iff MSB of data is processed at next clk cycle.
//  - pc_inc_o        High if pc shall be incremented.
//  - rf_ram_wstb_o   Strobe regfile write when implemented as BRAM.
//  - rf_ram_rstb_o   Strobe regfile read when implemented as BRAM.
//  - imem_stb_o      Instruction memory strobe.
//  - imem_ack_i      Instruction memory acknowledgement.
//  - dmem_stb_o      Data memory strobe.
//  - dmem_ack_i      Data memory acknowledgement.
//  - any_jmp_i       Current instruction is a jump.
//  - any_br_i        Current instruction is a branch.
//  - any_ld_i        Current instruction is a load.
//  - any_st_i        Current instruction is a store.
//  - any_shft_i      Current instruction is a shift.
//  - any_slt_i       Current instruction is a set less than.
//  - any_csr_i       Current instruction modies a CSR register.
//  - shft_done_i     Shift macro steps in spm_d is done.
//  - cyc_ack_o       In cycle: wait for ack.
//  - cyc_two_o       In cycle 2 (ICYC2).
//  - cyc_shft_o      In cycle: wait for shift to be done.
//  - hlt_regs_o      Halt registers, don't modify their content.
//  - hlt_spm_a_o     Halt spm_a, don't modify its content.
//  - hlt_imm_o       Halt register that holds the immediate.
//  - icyc_o          Number of instr. packed processed in that cycle.
// -----------------------------------------------------------------------------
//     / \       Initial version for evaluating scalability.       / \
//    / | \             _Not_ recommended for use.                / | \
//   /  .  \   Please use the version in `main` branch instead.  /  .  \
// -----------------------------------------------------------------------------

module fazyrv_cntrl #(
  parameter BWIDTH            = 2,
  parameter RF_TYPE           = "LOGIC",
  parameter REG_WIDTH         = 32,
  parameter CYCLES_PER_INSTR  = REG_WIDTH / BWIDTH,
  parameter CONF              = "CSR",
  parameter MEM_DLY_1         = 0
) (
  input  logic clk_i,
  input  logic rst_in,
  input  logic abort_i,
  input  logic pc_noinc_i,

  output logic lsb_o,
  output logic msb_o,
  output logic pc_inc_o,

  output logic rf_ram_wstb_o,
  output logic rf_ram_rstb_o,

  output logic imem_stb_o,
  input  logic imem_ack_i,
  output logic dmem_stb_o,
  input  logic dmem_ack_i,

  input  logic any_jmp_i,
  input  logic any_br_i,
  input  logic any_ld_i,
  input  logic any_st_i,
  input  logic any_shft_i,
  input  logic any_slt_i,
  input  logic any_csr_i,

  input  logic shft_done_i,

  output logic cyc_ack_o,
  output logic cyc_two_o,
  output logic cyc_two_shift_next_o,
  output logic cyc_shft_o,

  output logic hlt_regs_o,
  output logic hlt_spm_a_o,
  output logic hlt_imm_o,

  output logic [$clog2(CYCLES_PER_INSTR)-1:0] icyc_o
);

logic [$clog2(CYCLES_PER_INSTR)-1:0] cyc_r, cyc_n;

enum int unsigned { IFETCH, DECODE, DECODE2,
                    DECODE3, ICYC1, ICYC2,
                    ACK, SHIFT } state_r, state_n;

logic lsb_r;
logic icyc_done;

assign lsb_o  = lsb_r;
assign icyc_o = cyc_r;

always_ff @(posedge clk_i) begin
  lsb_r <= msb_o;
end

assign icyc_done  = (cyc_r == '1);

// Optimize: not compare with ICYC1
//
generate
  /* verilator lint_off WIDTHEXPAND */
  if ((CONF == "INT") | (CONF == "CSR")) begin
  /* verilator lint_on WIDTHEXPAND */
    assign pc_inc_o = ~(any_br_i | any_ld_i | any_st_i) ? (~pc_noinc_i & lsb_o & (state_r == ICYC1)) :
                                                          (~pc_noinc_i & lsb_o & (state_r == ICYC2));

  end else begin
    assign pc_inc_o = ~(any_br_i | any_ld_i | any_st_i) ? (lsb_o & (state_r == ICYC1)) :
                                                          (lsb_o & (state_r == ICYC2));
  end
endgenerate

always_ff @(posedge clk_i) begin
  if (~rst_in) begin
    cyc_r   <= 'b0;
    state_r <= IFETCH;
  end else begin
    cyc_r   <= cyc_n;
    state_r <= state_n;
  end
end

generate
  /* verilator lint_off WIDTHEXPAND */
  if (RF_TYPE == "LOGIC") begin
  /* verilator lint_on WIDTHEXPAND */
    assign rf_ram_wstb_o = 1'b0;
    assign rf_ram_rstb_o = 1'b0;
  end else begin
  /* verilator lint_off WIDTHEXPAND */
    assign rf_ram_wstb_o = (state_r == IFETCH) |
      ((CONF == "CSR") & (state_r == ICYC2) & lsb_r & any_csr_i);
//
//
  /* verilator lint_on WIDTHEXPAND */
    assign rf_ram_rstb_o = (state_r == DECODE) | (state_r == DECODE2);
  end
endgenerate

assign cyc_ack_o  = (state_r == ACK);
assign cyc_two_o  = (state_r == ICYC2);
assign cyc_shft_o = (state_r == SHIFT);
assign imem_stb_o = (state_r == IFETCH);

assign hlt_regs_o   = ~((state_r == ICYC1) | (state_r == ICYC2));
// don't shift shamt to the end s.t. shamt is available one cycle
// in advance
assign hlt_spm_a_o  = ~((state_r == ICYC1) & ~(any_shft_i & msb_o) );
assign dmem_stb_o   = (state_r == ACK);

// needed for MEM_DLY_1
assign cyc_two_shift_next_o = (state_n == ICYC2) | (state_n == SHIFT);


always_comb begin
  state_n   = state_r;
  cyc_n     = cyc_r + 'b1;
  hlt_imm_o = 1'b1;
  msb_o     = 1'b0;

  case (state_r)
    IFETCH: begin
      cyc_n = 'b0;
      msb_o = 1'b1;

      if (MEM_DLY_1 | imem_ack_i) begin
        state_n = DECODE;
      end
    end
    // ---
    DECODE: begin
      msb_o = 1'b1;
      cyc_n = 'b0;
      /* verilator lint_off WIDTHEXPAND */
      if ((RF_TYPE == "LOGIC") || (RF_TYPE == "BRAM_DP_BP")) begin
      /* verilator lint_on WIDTHEXPAND */
        state_n = ICYC1;
      end else begin
        state_n = DECODE2;
      end
    end
    // ---
    DECODE2: begin
      msb_o = 1'b1;
      cyc_n = 'b0;
      /* verilator lint_off WIDTHEXPAND */
      if ((RF_TYPE == "BRAM_BP") || (RF_TYPE == "BRAM_DP")) begin
      /* verilator lint_on WIDTHEXPAND */
        state_n = ICYC1;
      end else begin
        state_n = DECODE3;
      end
    end
    // ---
    DECODE3: begin
      msb_o   = 1'b1;
      state_n = ICYC1;
      cyc_n   = 'b0;
    end
    // ---
    ICYC1: begin
      hlt_imm_o = any_br_i;

      if (icyc_done) begin
        msb_o   = 1'b1;
        state_n = IFETCH;

        if (any_jmp_i | any_br_i | any_st_i | any_slt_i | any_csr_i)
          state_n = ICYC2;
        if (any_ld_i)
          state_n = ACK;
        if (any_shft_i) begin
          state_n = SHIFT;
          if (shft_done_i)
            state_n = ICYC2;
        end
        /* verilator lint_off WIDTHEXPAND */
        if ((CONF != "MIN") & abort_i)
          state_n = IFETCH;
        /* verilator lint_on WIDTHEXPAND */
      end
    end
    // ---
    ICYC2: begin
      hlt_imm_o = 1'b0;

      if (icyc_done) begin
        msb_o   = 1'b1;
        state_n = IFETCH;
        if (any_st_i) begin
          state_n = ACK;
        end
      end
    end
    // ---
    SHIFT: begin
      cyc_n = 'b0;
      if (shft_done_i) begin
        msb_o   = 1'b1;
        state_n = ICYC2;
      end
    end
    // ---
    ACK: begin
      cyc_n = 'b0;
      if (dmem_ack_i) begin
        msb_o = 1'b1;
        if (any_ld_i) begin
          if (shft_done_i) begin
            state_n = ICYC2;
          end else begin
            state_n = SHIFT;
          end
          // Currently there must be at least
          // one shfit with the spm_d implementation
          //state_n = SHIFT;
        end else begin
          state_n = IFETCH;
        end
      end
      /* verilator lint_off WIDTHEXPAND */
      if ((CONF != "MIN") & abort_i)
      /* verilator lint_on WIDTHEXPAND */
        state_n = IFETCH;
    end
    // ---
    default: begin
      msb_o   = 1'b1;
      state_n = IFETCH;
    end
  endcase
end

// -- Debug --

`ifdef DEBUG
(* keep *) logic [127:0] dbg_state;
always_comb begin
  case (state_r)
    IFETCH:   dbg_state = "fetch";
    DECODE:   dbg_state = "dec1";
    DECODE2:  dbg_state = "dec2";
    DECODE3:  dbg_state = "dec3";
    ICYC1:    dbg_state = "cyc1";
    ICYC2:    dbg_state = "cyc2";
    ACK:      dbg_state = "ack";
    SHIFT:    dbg_state = "shift";
    default:  dbg_state = "illegal";
  endcase
end
`endif

endmodule

