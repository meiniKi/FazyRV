// Copyright (c) 2025 - 2026 Meinhard Kissich
// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
// File  :  fazyrv_rvc.sv
// Usage :  Compressed instruction decoder.
// Partially based on
//  https://github.com/lowRISC/ibex/blob/master/rtl/ibex_compressed_decoder.sv
//
// Ports
//  - clk_i         Clock input, sensitive to rising edge.
//  - ack_i         Wishbone ack to keep is_rcv stable over the icycle.
//  - instr_c_i     Potentially compressed instruction input.
//  - instr_o       Uncompressed instruction output.
//  - is_rvc_o      Instruction is rvc.
// -----------------------------------------------------------------------------

module fazyrv_rvc (
  input  logic        clk_i,
  input  logic        ack_i,
  input  logic [31:0] instr_c_i,
  output logic [31:0] instr_o,
  output logic        is_rvc_o
);

logic is_rvc_r;
assign is_rvc_o = is_rvc_r;

always_ff @(posedge clk_i) begin
  if (ack_i) begin
    is_rvc_r <= ~&instr_c_i[1:0];
  end
end

logic [31:0] ins;
assign instr_o = ins;

localparam LW_OPC   = 5'b00000;
localparam SW_OPC   = 5'b01000;
localparam JAL_OPC  = 5'b11011;
localparam JALR_OPC = 5'b11001;
localparam BRN_OPC  = 5'b11000; 
localparam IMM_OPC  = 5'b00100;
localparam LUI_OPC  = 5'b01101;
localparam OP_OPC   = 5'b01100;


always_comb begin
  ins = {instr_c_i[31:2], 2'b11};

  unique case({instr_c_i[15:13], instr_c_i[1:0]})
    5'b010_10: begin
      // C.LWSP      -> lw rd,   imm.4(x2); (CI -> I)
      ins[6:2]    = LW_OPC;
      ins[14:12]  = instr_c_i[15:13]; // == 3'b010;
      ins[19:16]  = 4'b1;
      ins[31:28]  = 4'b0;
      ins[27:26]  = instr_c_i[3:2];
      ins[25]     = instr_c_i[12];
      ins[24:22]  = instr_c_i[6:4];
      ins[21:20]  = 2'b00;
    end

    5'b110_10: begin
      // C.SWSP      -> sw rs2,  imm.4(x2); (CSS -> S)
      ins[6:2]    = SW_OPC;
      ins[8:7]    = 2'b00;
      ins[11:9]   = instr_c_i[11:9];
      ins[14:12]  = instr_c_i[15:13] & 3'b011; // == 3'b010;
      ins[19:15]  = 5'b10;
      ins[24:20]  = instr_c_i[6:2];
      ins[25]     = instr_c_i[12];
      ins[27:26]  = instr_c_i[8:7];
      ins[31:28]  = 4'b0;
    end

    5'b010_00: begin
      // C.LW        -> lw rd',  imm.4(rs1'); (CL -> I)
      ins[6:2]    = LW_OPC;
      ins[11:7]   = {2'b01, instr_c_i[4:2]};
      ins[14:12]  = instr_c_i[15:13]; // == 3'b010;
      ins[19:15]  = {2'b01, instr_c_i[9:7]};
      ins[21:20]  = 2'b00;
      ins[22]     = instr_c_i[6];
      ins[25:23]  = instr_c_i[12:10];
      ins[26]     = instr_c_i[5];
      ins[31:27]  = 5'b0;
    end

    5'b110_00: begin
      // C.SW        -> sw rs1', imm.4(rs2'); (CS -> S)
      ins[6:2]    = SW_OPC;
      ins[8:7]    = 2'b0;
      ins[9]      = instr_c_i[6];
      ins[14:12]  = instr_c_i[15:13] & 3'b011; // == 3'b010
      ins[19:15]  = {2'b01, instr_c_i[9:7]};
      ins[24:20]  = {2'b01, instr_c_i[4:2]};
      ins[25]     = instr_c_i[12];
      ins[26]     = instr_c_i[5];
      ins[31:27]  = 5'b0;
    end

    5'b001_01,
    5'b101_01: begin
      // C.J         -> jal x0, offset.2; (CJ -> J)
      // C.JAL       -> jal ra, offset.2; (CJ -> J)
      ins[6:2]    = JAL_OPC;
      ins[7]      = ~instr_c_i[15];
      ins[11:8]   = 4'b0;
      ins[14:12]  = instr_c_i[15:13] | 3'b100;
      ins[20:12]  = {9{instr_c_i[12]}};
      ins[23:21]  = instr_c_i[5:3];
      ins[24]     = instr_c_i[11];
      ins[25]     = instr_c_i[2];
      ins[26]     = instr_c_i[7];
      ins[27]     = instr_c_i[6];
      ins[29:28]  = instr_c_i[10:9];
      ins[30]     = instr_c_i[8];
      ins[31]     = instr_c_i[12];
    end

    5'b100_10: begin
      if (|instr_c_i[6:2]) begin
        // C.MV, C.ADD
        ins[6:2]   = OP_OPC;
        ins[14:12] = instr_c_i[15:13] & 3'b011; // == 3'b0;
        ins[24:20] = instr_c_i[6:2];
        ins[31:25] = 7'b0;

        if (instr_c_i[12]) begin
          // C.ADD       -> add rd, rd, rs2; (CR -> R)
          ins[19:15] = instr_c_i[11:7];
        end else begin
          // C.MV        -> add rd, x0, rs2; (CB -> R)
          ins[19:15] = 5'b0;
          ins[24:20] = instr_c_i[6:2];
        end

      end else begin
        // C.JR, C.EBREAK, C.JALR
        if (instr_c_i[11:7] == 5'b0) begin
          // TODO not in MIN version; optimize instruction
          ins = {32'h00_10_00_73};
        end else begin
          // C.JR        -> jalr x0, rs1, 0; (CR -> I)
          ins[6:2]    = JALR_OPC;
          ins[11:7]   = {4'b0, instr_c_i[12]};
          ins[19:15]  = instr_c_i[11:7];
          ins[31:20]  = 12'b0;

          if (instr_c_i[12]) begin
            // C.JALR      -> jalr ra, rs1, 0; (CR -> I)
            ins[12]     = 1'b0;
            ins[31:20]  = 12'b0;
          end
        end
      end
    end

    5'b110_01,
    5'b111_01: begin
      // C.BEQZ      -> beq rs', x0, imm.2; (CB -> B)
      // C.BNEZ      -> bne rs', x0, imm.2; (CB -> B)
      ins[6:2]    = BRN_OPC;
      ins[7]      = instr_c_i[12];
      ins[9:8]    = instr_c_i[4:3];
      ins[14:12]  = {~instr_c_i[15:14], instr_c_i[13]}; // == {00,i[13]}
      ins[17:15]  = instr_c_i[9:7];
      ins[19:18]  = 2'b01;
      ins[24:20]  = 5'b0;
      ins[25]     = instr_c_i[2];
      ins[27:26]  = instr_c_i[6:5];
      ins[31:28]  = {4 {instr_c_i[12]}};           
    end


    5'b010_01: begin
      // C.LI        -> addi rd, x0, imm; (CI -> I)
      ins[6:2]    = IMM_OPC;
      ins[12]     = 1'b0;
      ins[14]     = 1'b0;
      ins[19:15]  = 5'b0;
      ins[24:20]  = instr_c_i[6:2];
      ins[25]     = instr_c_i[12];
      ins[31:26]  = {6{instr_c_i[12]}};
    end

    5'b011_01: begin
      // C.LUI       -> lui rd, imm; (CI -> U)
      ins[6:2]    = LUI_OPC;
      ins[16:12]  = instr_c_i[6:2];
      ins[31:17]  = {15{instr_c_i[12]}};

      if (instr_c_i[11:7] == 5'd2) begin
        // C.ADDI16SP  -> addi x2, x2, imm.16; (CI -> I)
        ins[6:2]    = IMM_OPC;
        ins[14:12]  = 3'b000;
        ins[19:15]  = 5'd2;
        ins[23:20]  = 4'b0;
        ins[24]     = instr_c_i[6];
        ins[25]     = instr_c_i[2];
        ins[26]     = instr_c_i[5];
        ins[28:27]  = instr_c_i[4:3];
        ins[31:29]  = {3{instr_c_i[12]}};
      end
    end

    5'b000_01: begin
      // C.ADDI      -> addi rd, rd, imm; (CI -> I)
      // C.NOP       -> addi x0, x0, 0; (CI -> I)
      ins[6:2]    = IMM_OPC;
      ins[12]     = 1'b0;
      ins[19:15]  = instr_c_i[11:7];
      ins[24:20]  = instr_c_i[6:2];
      ins[25]     = instr_c_i[12];
      ins[31:26]  = {6{instr_c_i[12]}};
    end

    5'b000_00: begin
      // C.ADDI4SPN  -> addi, rd', x2, imm.4; (CI -> I)
      ins[6:2]    = IMM_OPC;
      ins[11:7]   = {2'b01, instr_c_i[4:2]};
      ins[12]     = 1'b0;
      ins[19:15]  = 5'h02;
      ins[21:20]  = 2'b00;
      ins[22]     = instr_c_i[6];
      ins[23]     = instr_c_i[5];
      ins[25:24]  = instr_c_i[12:11];
      ins[29:26]  = instr_c_i[10:7];
      ins[31:30]  = 2'b0;
    end

    5'b000_10: begin
      // C.SLLI      -> slli rd, rd, imm; (CI -> I)
      ins[6:2]    = IMM_OPC;
      ins[12]     = 1'b1;
      ins[19:15]  = instr_c_i[11:7];
      ins[24:20]  = instr_c_i[6:2];
      ins[31:25]  = 7'b0;
    end

    5'b100_01: begin
      ins[6:2]    = IMM_OPC;
      ins[11:10]  = 2'b01;
      ins[19:15]  = {2'b01, instr_c_i[9:7]};
      ins[24:20]  = instr_c_i[6:2];

      unique case (instr_c_i[11:10])
      2'b10: begin
        // C.ANDI      -> andi rd', rd', imm; (CB -> I)
        ins[14:12]  = 3'b111;
        ins[25]     = instr_c_i[12];
        ins[31:26]  = {6{instr_c_i[12]}};
      end

      2'b11: begin
        // C.AND, C.OR, C.XOR, C.SUB
        ins[6:2]   = OP_OPC;
        ins[11:7]  = {2'b01, instr_c_i[9:7]};
        ins[19:15] = {2'b01, instr_c_i[9:7]};
        ins[24:20] = {2'b01, instr_c_i[4:2]};

        // 1 only for sub
        ins[31:25] = {1'b0, ~|instr_c_i[6:5], 5'b0};

        unique case (instr_c_i[6:5])
          //  C.SUB       -> sub rd', rd', rs2'
          2'b00: ins[14:12] = 3'b000;
          // C.XOR       -> xor rd', rd', rs2'
          2'b01: ins[14:12] = 3'b100;
          // C.OR        -> or rd', rd', rs2'
          2'b10: ins[14:12] = 3'b110;
          // C.AND       -> and rd', rd', rs2' (CS -> R)
          2'b11: ins[14:12] = 3'b111;
        endcase
      end
      
      default: begin
        // C.SRLI      -> srli rd', rd', imm; (CB -> I)
        // C.SRAI      -> srai rd', rd', imm; (CB -> I)
        ins[14:12]  = 3'b101;
        ins[29:25]  = 5'b0;
        ins[30]     = instr_c_i[10];
        ins[31]     = 1'b0;
      end
      endcase
    end

    default: begin end
  endcase
end

endmodule