// Module này được dùng cho mục đích debug và trace (theo dõi) việc thực thi các lệnh trong CPU RISC-V. 
// Nó chuyển đổi mã máy (machine code) sang dạng assembly dễ đọc.
`include "riscv_base_defines.v"

module riscv_base_trace_sim(
    input valid_i,
    input [31:0] pc_i,
    input [31:0] opcode_i
);

function [79:0] get_regname_str;
    input [4:0] regnum;
    begin
        case (regnum)
            5'd0:  get_regname_str = "zero";
            5'd1:  get_regname_str = "ra";
            5'd2:  get_regname_str = "sp";
            5'd3:  get_regname_str = "gp";
            5'd4:  get_regname_str = "tp";
            5'd5:  get_regname_str = "t0";
            5'd6:  get_regname_str = "t1";
            5'd7:  get_regname_str = "t2";
            5'd8:  get_regname_str = "s0";
            5'd9:  get_regname_str = "s1";
            5'd10: get_regname_str = "a0";
            5'd11: get_regname_str = "a1";
            5'd12: get_regname_str = "a2";
            5'd13: get_regname_str = "a3";
            5'd14: get_regname_str = "a4";
            5'd15: get_regname_str = "a5";
            5'd16: get_regname_str = "a6";
            5'd17: get_regname_str = "a7";
            5'd18: get_regname_str = "s2";
            5'd19: get_regname_str = "s3";
            5'd20: get_regname_str = "s4";
            5'd21: get_regname_str = "s5";
            5'd22: get_regname_str = "s6";
            5'd23: get_regname_str = "s7";
            5'd24: get_regname_str = "s8";
            5'd25: get_regname_str = "s9";
            5'd26: get_regname_str = "s10";
            5'd27: get_regname_str = "s11";
            5'd28: get_regname_str = "t3";
            5'd29: get_regname_str = "t4";
            5'd30: get_regname_str = "t5";
            5'd31: get_regname_str = "t6";
            default: get_regname_str = "???";
        endcase
    end
endfunction

// Function để check instruction match với mask
function inst_match;
    input [31:0] opcode;
    input [31:0] inst_pattern;
    input [31:0] inst_mask;
    begin
        inst_match = ((opcode & inst_mask) == (inst_pattern & inst_mask));
    end
endfunction

// debug outputs
reg [79:0] dbg_inst_str;  // Lưu tên lệnh dạng chuỗi
reg [79:0] dbg_inst_ra;   // Tên thanh ghi nguồn thứ 1
reg [79:0] dbg_inst_rb;   // Tên thanh ghi nguồn thứ 2  
reg [79:0] dbg_inst_rd;   // Tên thanh ghi đích
reg [31:0] dbg_inst_imm;  // Giá trị immediate
reg [31:0] dbg_inst_pc;   // Program counter

// Địa chỉ thanh ghi
wire [4:0] ra_idx_w = opcode_i[19:15];  // rs1
wire [4:0] rb_idx_w = opcode_i[24:20];  // rs2
wire [4:0] rd_idx_w = opcode_i[11:7];   // rd

// Định nghĩa các immediate fields
`define DBG_IMM_IMM20     {opcode_i[31:12], 12'b0}
`define DBG_IMM_IMM12     {{20{opcode_i[31]}}, opcode_i[31:20]}
`define DBG_IMM_BIMM      {{19{opcode_i[31]}}, opcode_i[31], opcode_i[7], opcode_i[30:25], opcode_i[11:8], 1'b0}
`define DBG_IMM_JIMM20    {{11{opcode_i[31]}}, opcode_i[31], opcode_i[19:12], opcode_i[20], opcode_i[30:21], 1'b0}
`define DBG_IMM_STOREIMM  {{20{opcode_i[31]}}, opcode_i[31:25], opcode_i[11:7]}
`define DBG_IMM_SHAMT     opcode_i[24:20]

always @(*) begin
    // Default values
    dbg_inst_str = "-";
    dbg_inst_ra  = "-";
    dbg_inst_rb  = "-";
    dbg_inst_rd  = "-";
    dbg_inst_imm = 32'h0;
    dbg_inst_pc  = 32'bx;

    if (valid_i) begin
        dbg_inst_pc  = pc_i;
        dbg_inst_ra  = get_regname_str(ra_idx_w);
        dbg_inst_rb  = get_regname_str(rb_idx_w);
        dbg_inst_rd  = get_regname_str(rd_idx_w);

        // Instruction decode using mask matching
        if (inst_match(opcode_i, `INST_ANDI, `INST_ANDI_MASK)) begin
            dbg_inst_str = "andi";
            dbg_inst_rb  = "-";
            dbg_inst_imm = `DBG_IMM_IMM12;
        end
        else if (inst_match(opcode_i, `INST_ADDI, `INST_ADDI_MASK)) begin
            dbg_inst_str = "addi";
            dbg_inst_rb  = "-";
            dbg_inst_imm = `DBG_IMM_IMM12;
        end
        else if (inst_match(opcode_i, `INST_SLTI, `INST_SLTI_MASK)) begin
            dbg_inst_str = "slti";
            dbg_inst_rb  = "-";
            dbg_inst_imm = `DBG_IMM_IMM12;
        end
        else if (inst_match(opcode_i, `INST_SLTIU, `INST_SLTIU_MASK)) begin
            dbg_inst_str = "sltiu";
            dbg_inst_rb  = "-";
            dbg_inst_imm = `DBG_IMM_IMM12;
        end
        else if (inst_match(opcode_i, `INST_ORI, `INST_ORI_MASK)) begin
            dbg_inst_str = "ori";
            dbg_inst_rb  = "-";
            dbg_inst_imm = `DBG_IMM_IMM12;
        end
        else if (inst_match(opcode_i, `INST_XORI, `INST_XORI_MASK)) begin
            dbg_inst_str = "xori";
            dbg_inst_rb  = "-";
            dbg_inst_imm = `DBG_IMM_IMM12;
        end
        else if (inst_match(opcode_i, `INST_SLLI, `INST_SLLI_MASK)) begin
            dbg_inst_str = "slli";
            dbg_inst_rb  = "-";
            dbg_inst_imm = {27'b0, `DBG_IMM_SHAMT};
        end
        else if (inst_match(opcode_i, `INST_SRLI, `INST_SRLI_MASK)) begin
            dbg_inst_str = "srli";
            dbg_inst_rb  = "-";
            dbg_inst_imm = {27'b0, `DBG_IMM_SHAMT};
        end
        else if (inst_match(opcode_i, `INST_SRAI, `INST_SRAI_MASK)) begin
            dbg_inst_str = "srai";
            dbg_inst_rb  = "-";
            dbg_inst_imm = {27'b0, `DBG_IMM_SHAMT};
        end
        else if (inst_match(opcode_i, `INST_LUI, `INST_LUI_MASK)) begin
            dbg_inst_str = "lui";
            dbg_inst_ra  = "-";
            dbg_inst_rb  = "-";
            dbg_inst_imm = `DBG_IMM_IMM20;
        end
        else if (inst_match(opcode_i, `INST_AUIPC, `INST_AUIPC_MASK)) begin
            dbg_inst_str = "auipc";
            dbg_inst_ra  = "pc";
            dbg_inst_rb  = "-";
            dbg_inst_imm = `DBG_IMM_IMM20;
        end
        else if (inst_match(opcode_i, `INST_ADD, `INST_ADD_MASK)) begin
            dbg_inst_str = "add";
            dbg_inst_imm = 32'h0;
        end
        else if (inst_match(opcode_i, `INST_SUB, `INST_SUB_MASK)) begin
            dbg_inst_str = "sub";
            dbg_inst_imm = 32'h0;
        end
        else if (inst_match(opcode_i, `INST_SLT, `INST_SLT_MASK)) begin
            dbg_inst_str = "slt";
            dbg_inst_imm = 32'h0;
        end
        else if (inst_match(opcode_i, `INST_SLTU, `INST_SLTU_MASK)) begin
            dbg_inst_str = "sltu";
            dbg_inst_imm = 32'h0;
        end
        else if (inst_match(opcode_i, `INST_XOR, `INST_XOR_MASK)) begin
            dbg_inst_str = "xor";
            dbg_inst_imm = 32'h0;
        end
        else if (inst_match(opcode_i, `INST_OR, `INST_OR_MASK)) begin
            dbg_inst_str = "or";
            dbg_inst_imm = 32'h0;
        end
        else if (inst_match(opcode_i, `INST_AND, `INST_AND_MASK)) begin
            dbg_inst_str = "and";
            dbg_inst_imm = 32'h0;
        end
        else if (inst_match(opcode_i, `INST_SLL, `INST_SLL_MASK)) begin
            dbg_inst_str = "sll";
            dbg_inst_imm = 32'h0;
        end
        else if (inst_match(opcode_i, `INST_SRL, `INST_SRL_MASK)) begin
            dbg_inst_str = "srl";
            dbg_inst_imm = 32'h0;
        end
        else if (inst_match(opcode_i, `INST_SRA, `INST_SRA_MASK)) begin
            dbg_inst_str = "sra";
            dbg_inst_imm = 32'h0;
        end
        else if (inst_match(opcode_i, `INST_JAL, `INST_JAL_MASK)) begin
            dbg_inst_str = "jal";
            dbg_inst_ra  = "-";
            dbg_inst_rb  = "-";
            dbg_inst_imm = pc_i + `DBG_IMM_JIMM20;
            if (rd_idx_w == 5'd1)
                dbg_inst_str = "call";
        end
        else if (inst_match(opcode_i, `INST_JALR, `INST_JALR_MASK)) begin
            dbg_inst_str = "jalr";
            dbg_inst_rb  = "-";
            dbg_inst_imm = `DBG_IMM_IMM12;
            if (ra_idx_w == 5'd1 && `DBG_IMM_IMM12 == 32'b0)
                dbg_inst_str = "ret";
            else if (rd_idx_w == 5'd1)
                dbg_inst_str = "call (R)";
        end
        else if (inst_match(opcode_i, `INST_BEQ, `INST_BEQ_MASK)) begin
            dbg_inst_str = "beq";
            dbg_inst_rd  = "-";
            dbg_inst_imm = pc_i + `DBG_IMM_BIMM;
        end
        else if (inst_match(opcode_i, `INST_BNE, `INST_BNE_MASK)) begin
            dbg_inst_str = "bne";
            dbg_inst_rd  = "-";
            dbg_inst_imm = pc_i + `DBG_IMM_BIMM;
        end
        else if (inst_match(opcode_i, `INST_BLT, `INST_BLT_MASK)) begin
            dbg_inst_str = "blt";
            dbg_inst_rd  = "-";
            dbg_inst_imm = pc_i + `DBG_IMM_BIMM;
        end
        else if (inst_match(opcode_i, `INST_BGE, `INST_BGE_MASK)) begin
            dbg_inst_str = "bge";
            dbg_inst_rd  = "-";
            dbg_inst_imm = pc_i + `DBG_IMM_BIMM;
        end
        else if (inst_match(opcode_i, `INST_BLTU, `INST_BLTU_MASK)) begin
            dbg_inst_str = "bltu";
            dbg_inst_rd  = "-";
            dbg_inst_imm = pc_i + `DBG_IMM_BIMM;
        end
        else if (inst_match(opcode_i, `INST_BGEU, `INST_BGEU_MASK)) begin
            dbg_inst_str = "bgeu";
            dbg_inst_rd  = "-";
            dbg_inst_imm = pc_i + `DBG_IMM_BIMM;
        end
        else if (inst_match(opcode_i, `INST_LB, `INST_LB_MASK)) begin
            dbg_inst_str = "lb";
            dbg_inst_rb  = "-";
            dbg_inst_imm = `DBG_IMM_IMM12;
        end
        else if (inst_match(opcode_i, `INST_LH, `INST_LH_MASK)) begin
            dbg_inst_str = "lh";
            dbg_inst_rb  = "-";
            dbg_inst_imm = `DBG_IMM_IMM12;
        end
        else if (inst_match(opcode_i, `INST_LW, `INST_LW_MASK)) begin
            dbg_inst_str = "lw";
            dbg_inst_rb  = "-";
            dbg_inst_imm = `DBG_IMM_IMM12;
        end
        else if (inst_match(opcode_i, `INST_LBU, `INST_LBU_MASK)) begin
            dbg_inst_str = "lbu";
            dbg_inst_rb  = "-";
            dbg_inst_imm = `DBG_IMM_IMM12;
        end
        else if (inst_match(opcode_i, `INST_LHU, `INST_LHU_MASK)) begin
            dbg_inst_str = "lhu";
            dbg_inst_rb  = "-";
            dbg_inst_imm = `DBG_IMM_IMM12;
        end
        else if (inst_match(opcode_i, `INST_LWU, `INST_LWU_MASK)) begin
            dbg_inst_str = "lwu";
            dbg_inst_rb  = "-";
            dbg_inst_imm = `DBG_IMM_IMM12;
        end
        else if (inst_match(opcode_i, `INST_SB, `INST_SB_MASK)) begin
            dbg_inst_str = "sb";
            dbg_inst_rd  = "-";
            dbg_inst_imm = `DBG_IMM_STOREIMM;
        end
        else if (inst_match(opcode_i, `INST_SH, `INST_SH_MASK)) begin
            dbg_inst_str = "sh";
            dbg_inst_rd  = "-";
            dbg_inst_imm = `DBG_IMM_STOREIMM;
        end
        else if (inst_match(opcode_i, `INST_SW, `INST_SW_MASK)) begin
            dbg_inst_str = "sw";
            dbg_inst_rd  = "-";
            dbg_inst_imm = `DBG_IMM_STOREIMM;
        end
        else if (inst_match(opcode_i, `INST_ECALL, `INST_ECALL_MASK)) begin
            dbg_inst_str = "ecall";
            dbg_inst_ra  = "-";
            dbg_inst_rb  = "-";
            dbg_inst_rd  = "-";
            dbg_inst_imm = 32'h0;
        end
        else if (inst_match(opcode_i, `INST_EBREAK, `INST_EBREAK_MASK)) begin
            dbg_inst_str = "ebreak";
            dbg_inst_ra  = "-";
            dbg_inst_rb  = "-";
            dbg_inst_rd  = "-";
            dbg_inst_imm = 32'h0;
        end
        else if (inst_match(opcode_i, `INST_ERET, `INST_ERET_MASK)) begin
            dbg_inst_str = "eret";
            dbg_inst_ra  = "-";
            dbg_inst_rb  = "-";
            dbg_inst_rd  = "-";
            dbg_inst_imm = 32'h0;
        end
        else if (inst_match(opcode_i, `INST_CSRRW, `INST_CSRRW_MASK)) begin
            dbg_inst_str = "csrrw";
            dbg_inst_rb  = "-";
            dbg_inst_imm = `DBG_IMM_IMM12;
        end
        else if (inst_match(opcode_i, `INST_CSRRS, `INST_CSRRS_MASK)) begin
            dbg_inst_str = "csrrs";
            dbg_inst_rb  = "-";
            dbg_inst_imm = `DBG_IMM_IMM12;
        end
        else if (inst_match(opcode_i, `INST_CSRRC, `INST_CSRRC_MASK)) begin
            dbg_inst_str = "csrrc";
            dbg_inst_rb  = "-";
            dbg_inst_imm = `DBG_IMM_IMM12;
        end
        else if (inst_match(opcode_i, `INST_CSRRWI, `INST_CSRRWI_MASK)) begin
            dbg_inst_str = "csrrwi";
            dbg_inst_rb  = "-";
            dbg_inst_imm = `DBG_IMM_IMM12;
        end
        else if (inst_match(opcode_i, `INST_CSRRSI, `INST_CSRRSI_MASK)) begin
            dbg_inst_str = "csrrsi";
            dbg_inst_rb  = "-";
            dbg_inst_imm = `DBG_IMM_IMM12;
        end
        else if (inst_match(opcode_i, `INST_CSRRCI, `INST_CSRRCI_MASK)) begin
            dbg_inst_str = "csrrci";
            dbg_inst_rb  = "-";
            dbg_inst_imm = `DBG_IMM_IMM12;
        end
        else if (inst_match(opcode_i, `INST_MUL, `INST_MUL_MASK)) begin
            dbg_inst_str = "mul";
            dbg_inst_imm = 32'h0;
        end
        else if (inst_match(opcode_i, `INST_MULH, `INST_MULH_MASK)) begin
            dbg_inst_str = "mulh";
            dbg_inst_imm = 32'h0;
        end
        else if (inst_match(opcode_i, `INST_MULHSU, `INST_MULHSU_MASK)) begin
            dbg_inst_str = "mulhsu";
            dbg_inst_imm = 32'h0;
        end
        else if (inst_match(opcode_i, `INST_MULHU, `INST_MULHU_MASK)) begin
            dbg_inst_str = "mulhu";
            dbg_inst_imm = 32'h0;
        end
        else if (inst_match(opcode_i, `INST_DIV, `INST_DIV_MASK)) begin
            dbg_inst_str = "div";
            dbg_inst_imm = 32'h0;
        end
        else if (inst_match(opcode_i, `INST_DIVU, `INST_DIVU_MASK)) begin
            dbg_inst_str = "divu";
            dbg_inst_imm = 32'h0;
        end
        else if (inst_match(opcode_i, `INST_REM, `INST_REM_MASK)) begin
            dbg_inst_str = "rem";
            dbg_inst_imm = 32'h0;
        end
        else if (inst_match(opcode_i, `INST_REMU, `INST_REMU_MASK)) begin
            dbg_inst_str = "remu";
            dbg_inst_imm = 32'h0;
        end
        else if (inst_match(opcode_i, `INST_IFENCE, `INST_IFENCE_MASK)) begin
            dbg_inst_str = "fence.i";
            dbg_inst_ra  = "-";
            dbg_inst_rb  = "-";
            dbg_inst_rd  = "-";
            dbg_inst_imm = 32'h0;
        end
        else begin
            dbg_inst_str = "unknown";
            dbg_inst_ra  = "-";
            dbg_inst_rb  = "-"; 
            dbg_inst_rd  = "-";
            dbg_inst_imm = 32'h0;
        end
    end
end

// Display task for debugging
task display_instruction;
    if (valid_i) begin
        $display("[%08h] %s %s, %s, %s (imm=%08h)", 
                 dbg_inst_pc, dbg_inst_str, dbg_inst_rd, dbg_inst_ra, dbg_inst_rb, dbg_inst_imm);
    end
endtask

endmodule