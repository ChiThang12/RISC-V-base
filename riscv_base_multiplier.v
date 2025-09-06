module riscv_base_multiplier(
    input           clk_i,
    input           rst_i,
    input           hold_i,

    input           opcode_valid_i,
    input  [31:0]   opcode_opcode_i,
    input  [31:0]   opcode_pc_i,
    input           opcode_invalid_i,

    input  [4:0]    opcode_rd_idx_i,
    input  [4:0]    opcode_ra_idx_i,
    input  [4:0]    opcode_rb_idx_i,

    input  [31:0]   opcode_ra_operand_i,
    input  [31:0]   opcode_rb_operand_i,

    output [31:0]   writeback_value_o
);
    `include "riscv_base_defines.v"

    localparam MULT_STAGES = 2;

    // pipeline registers
    reg [32:0] operand_a_e1_q;
    reg [32:0] operand_b_e1_q;
    reg        mulhi_sel_e1_q;
    reg [31:0] result_e2_q;
    reg [31:0] result_e3_q;

    // temporary wires
    reg [32:0] operand_a_r;
    reg [32:0] operand_b_r;
    wire [63:0] mult_result_w;
    reg [31:0] result_r;

    // decode instruction
    wire inst_mul    = ((opcode_opcode_i & `INST_MUL_MASK)    == `INST_MUL);
    wire inst_mulh   = ((opcode_opcode_i & `INST_MULH_MASK)   == `INST_MULH);
    wire inst_mulhsu = ((opcode_opcode_i & `INST_MULHSU_MASK) == `INST_MULHSU);
    wire inst_mulhu  = ((opcode_opcode_i & `INST_MULHU_MASK)  == `INST_MULHU);

    wire mult_inst_w = inst_mul | inst_mulh | inst_mulhsu | inst_mulhu;

    // chọn operand A/B (có sign-extend hoặc zero-extend thành 33 bit)
    always @(*) begin
        if (inst_mulhsu) begin
            operand_a_r = {opcode_ra_operand_i[31], opcode_ra_operand_i};
            operand_b_r = {1'b0, opcode_rb_operand_i};
        end else if (inst_mulh) begin
            operand_a_r = {opcode_ra_operand_i[31], opcode_ra_operand_i};
            operand_b_r = {opcode_rb_operand_i[31], opcode_rb_operand_i};
        end else begin // MUL hoặc MULHU
            operand_a_r = {1'b0, opcode_ra_operand_i};
            operand_b_r = {1'b0, opcode_rb_operand_i};
        end
    end

    // pipeline stage E1
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            operand_a_e1_q <= 33'b0;
            operand_b_e1_q <= 33'b0;
            mulhi_sel_e1_q <= 1'b0;
        end else if (hold_i) begin
            // giữ giá trị
            operand_a_e1_q <= operand_a_e1_q;
            operand_b_e1_q <= operand_b_e1_q;
            mulhi_sel_e1_q <= mulhi_sel_e1_q;
        end else if (opcode_valid_i && mult_inst_w) begin
            operand_a_e1_q <= operand_a_r;
            operand_b_e1_q <= operand_b_r;
            mulhi_sel_e1_q <= ~inst_mul; // chọn high phần khi không phải MUL
        end else begin
            operand_a_e1_q <= 33'b0;
            operand_b_e1_q <= 33'b0;
            mulhi_sel_e1_q <= 1'b0;
        end
    end

    // multiplier 33x33 -> 64 bit
    assign mult_result_w = $signed({{31{operand_a_e1_q[32]}}, operand_a_e1_q}) *
                           $signed({{31{operand_b_e1_q[32]}}, operand_b_e1_q});

    // chọn kết quả high/low
    always @(*) begin
        result_r = mulhi_sel_e1_q ? mult_result_w[63:32] : mult_result_w[31:0];
    end

    // pipeline stage E2
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i)
            result_e2_q <= 32'b0;
        else if (~hold_i)
            result_e2_q <= result_r;
    end

    // pipeline stage E3
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i)
            result_e3_q <= 32'b0;
        else if (~hold_i)
            result_e3_q <= result_e2_q;
    end

    // output chọn theo MULT_STAGES
    assign writeback_value_o = opcode_invalid_i ? 32'b0 :
                              (MULT_STAGES == 2) ? result_e2_q : result_e3_q;

endmodule

