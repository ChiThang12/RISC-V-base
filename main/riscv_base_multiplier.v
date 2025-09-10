module riscv_base_multiplier (
    // Inputs
    input           clk_i,
    input           rst_i,
    input           opcode_valid_i,
    input  [31:0]   opcode_opcode_i,
    input  [31:0]   opcode_pc_i,
    input           opcode_invalid_i,
    input  [4:0]    opcode_rd_idx_i,
    input  [4:0]    opcode_ra_idx_i,
    input  [4:0]    opcode_rb_idx_i,
    input  [31:0]   opcode_ra_operand_i, // Toán hạng a
    input  [31:0]   opcode_rb_operand_i, // Toán hạng b
    input           hold_i,
    // Outputs
    output [31:0]   writeback_value_o
);

    // Bao gồm định nghĩa RISC-V
    `include "riscv_base_defines.v"

    // Tham số pipeline
    localparam MULT_STAGES = 2; // 2 giai đoạn

    //-------------------------------------------------------------
    // Thanh ghi và dây
    //-------------------------------------------------------------
    reg  [31:0] result_e2_q;    // Thanh ghi giai đoạn E2
    reg         valid_e1_q;     // Thanh ghi valid giai đoạn E1
    reg         mulhi_sel_e1_q; // Chọn phần cao/thấp
    wire [63:0] mult_result_w;  // Kết quả nhân 64-bit
    wire [31:0] result_w;       // Kết quả tổ hợp

    //-------------------------------------------------------------
    // Giải mã lệnh
    //-------------------------------------------------------------
    wire inst_mul_w    = (opcode_opcode_i & `INST_MUL_MASK)    == `INST_MUL;
    wire inst_mulh_w   = (opcode_opcode_i & `INST_MULH_MASK)   == `INST_MULH;
    wire inst_mulhsu_w = (opcode_opcode_i & `INST_MULHSU_MASK) == `INST_MULHSU;
    wire inst_mulhu_w  = (opcode_opcode_i & `INST_MULHU_MASK)  == `INST_MULHU;
    wire mult_inst_w   = inst_mul_w | inst_mulh_w | inst_mulhsu_w | inst_mulhu_w;

    //-------------------------------------------------------------
    // Lựa chọn toán hạng (sign/zero extension)
    //-------------------------------------------------------------
    wire [63:0] operand_a_w = (inst_mulh_w | inst_mulhsu_w) ? 
                             {{32{opcode_ra_operand_i[31]}}, opcode_ra_operand_i} : // Có dấu
                             {32'h0, opcode_ra_operand_i};                         // Không dấu
    wire [63:0] operand_b_w = inst_mulh_w ? 
                             {{32{opcode_rb_operand_i[31]}}, opcode_rb_operand_i} : // Có dấu
                             {32'h0, opcode_rb_operand_i};                         // Không dấu
    wire mulhi_sel_w = inst_mulh_w | inst_mulhsu_w | inst_mulhu_w;

    //-------------------------------------------------------------
    // Giai đoạn E1: Lưu toán hạng và valid
    //-------------------------------------------------------------
    reg [63:0] operand_a_e1_q;
    reg [63:0] operand_b_e1_q;

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            operand_a_e1_q <= 64'b0;
            operand_b_e1_q <= 64'b0;
            valid_e1_q <= 1'b0;
            mulhi_sel_e1_q <= 1'b0;
        end else if (hold_i) begin
            operand_a_e1_q <= operand_a_e1_q;
            operand_b_e1_q <= operand_b_e1_q;
            valid_e1_q <= valid_e1_q;
            mulhi_sel_e1_q <= mulhi_sel_e1_q;
        end else begin
            operand_a_e1_q <= operand_a_w;
            operand_b_e1_q <= operand_b_w;
            valid_e1_q <= opcode_valid_i && mult_inst_w;
            mulhi_sel_e1_q <= mulhi_sel_w;
        end
    end

    //-------------------------------------------------------------
    // Bộ nhân low-level (sử dụng toán tử *)
    //-------------------------------------------------------------
    assign mult_result_w = $signed(operand_a_e1_q) * $signed(operand_b_e1_q);

    // Lựa chọn phần cao hoặc thấp
    assign result_w = mulhi_sel_e1_q ? mult_result_w[63:32] : mult_result_w[31:0];

    //-------------------------------------------------------------
    // Giai đoạn E2: Lưu kết quả
    //-------------------------------------------------------------
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i)
            result_e2_q <= 32'b0;
        else if (~hold_i && valid_e1_q)
            result_e2_q <= result_w;
        else if (~hold_i)
            result_e2_q <= 32'b0; // Xóa kết quả nếu không valid
    end

    //-------------------------------------------------------------
    // Đầu ra
    //-------------------------------------------------------------
    assign writeback_value_o = opcode_invalid_i ? 32'b0 : result_e2_q;

endmodule