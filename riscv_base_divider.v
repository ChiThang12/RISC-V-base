
module riscv_base_divider (
    input           clk_i,
    input           rst_i,
    input           opcode_valid_i,     // Báo hiệu lệnh đầu vào hợp lệ, bắt đầu chia
    input  [31:0]   opcode_opcode_i,    // Mã lệnh opcode
    input  [31:0]   opcode_pc_i,        // Địa chỉ lệnh hiện tại (Program Counter)
    input           opcode_invalid_i,   // Báo hiệu lệnh đầu vào không hợp lệ
    input  [4:0]    opcode_rd_idx_i,    // Chỉ số thanh ghi đích (rd)
    input  [4:0]    opcode_ra_idx_i,    // Chỉ số thanh ghi nguồn 1 (ra)
    input  [4:0]    opcode_rb_idx_i,    // Chỉ số thanh ghi nguồn 2 (rb)
    input  [31:0]   opcode_ra_operand_i,// Số bị chia (dividend)
    input  [31:0]   opcode_rb_operand_i,// Số chia (divisor)
    output          writeback_valid_o,  // Báo hiệu kết quả sẵn sàng
    output [31:0]   writeback_value_o   // Kết quả phép chia hoặc dư
);

    `include "riscv_base_defines.v"

    // --- Instruction Decoding ---
    wire inst_div_w  = (opcode_opcode_i & `INST_DIV_MASK) == `INST_DIV;    // Chia có dấu
    wire inst_divu_w = (opcode_opcode_i & `INST_DIVU_MASK) == `INST_DIVU;  // Chia không dấu
    wire inst_rem_w  = (opcode_opcode_i & `INST_REM_MASK) == `INST_REM;    // Dư có dấu
    wire inst_remu_w = (opcode_opcode_i & `INST_REMU_MASK) == `INST_REMU;  // Dư không dấu

    wire div_rem_inst_w = inst_div_w | inst_divu_w | inst_rem_w | inst_remu_w;
    wire signed_operation_w = inst_div_w | inst_rem_w;
    wire div_operation_w = inst_div_w | inst_divu_w;

    // --- Special Cases ---
    wire div_by_zero_w = (opcode_rb_operand_i == 32'h0);
    wire overflow_w = signed_operation_w & (opcode_ra_operand_i == 32'h80000000) & 
                     (opcode_rb_operand_i == 32'hFFFFFFFF);

    // --- Control Signals ---
    wire div_start_w = opcode_valid_i & div_rem_inst_w & ~opcode_invalid_i & 
                      ~div_by_zero_w & ~overflow_w;
    wire div_complete_w = (q_mask_q == 32'h0) & div_busy_q;

    // --- Registers ---
    reg [31:0] dividend_q;    // Số bị chia hoặc dư tạm thời
    reg [31:0] divisor_q;     // Số chia
    reg [31:0] quotient_q;    // Thương
    reg [31:0] q_mask_q;      // Mặt nạ bit
    reg        div_inst_q;    // 1: DIV/DIVU, 0: REM/REMU
    reg        div_busy_q;    // 1: Đang chia
    reg        invert_res_q;  // 1: Đảo dấu kết quả
    reg        valid_q;       // Trạng thái hợp lệ
    reg [31:0] wb_result_q;   // Kết quả ghi ngược

    // --- Reset Logic ---
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            div_busy_q   <= 1'b0;
            dividend_q   <= 32'h0;
            divisor_q    <= 32'h0;
            quotient_q   <= 32'h0;
            q_mask_q     <= 32'h0;
            div_inst_q   <= 1'b0;
            invert_res_q <= 1'b0;
        end
    end

    // --- Division Start Logic ---
    always @(posedge clk_i) begin
        if (div_start_w) begin
            div_busy_q <= 1'b1;
            div_inst_q <= div_operation_w;

            // Xử lý dấu cho số bị chia
            dividend_q <= signed_operation_w & opcode_ra_operand_i[31] ? 
                         ~opcode_ra_operand_i + 1 : opcode_ra_operand_i;

            // Xử lý dấu cho số chia
            divisor_q <= signed_operation_w & opcode_rb_operand_i[31] ? 
                        ~opcode_rb_operand_i + 1 : opcode_rb_operand_i;

            // Xác định đảo dấu kết quả
            invert_res_q <= (inst_div_w & (opcode_ra_operand_i[31] ^ opcode_rb_operand_i[31]) & |opcode_rb_operand_i) |
                           (inst_rem_w & opcode_ra_operand_i[31]);

            quotient_q <= 32'h0;
            q_mask_q   <= 32'h80000000;
        end
    end

    // --- Division Process Logic ---
    always @(posedge clk_i) begin
        if (div_busy_q & ~div_complete_w) begin
            if (dividend_q >= divisor_q) begin
                dividend_q <= dividend_q - divisor_q;
                quotient_q <= quotient_q | q_mask_q;
            end
            divisor_q <= divisor_q >> 1;
            q_mask_q  <= q_mask_q >> 1;
        end
    end

    // --- Division Complete Logic ---
    always @(posedge clk_i) begin
        if (div_complete_w) begin
            div_busy_q <= 1'b0;
        end
    end

    // --- Writeback Valid Logic ---
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            valid_q <= 1'b0;
        end else begin
            valid_q <= div_complete_w | div_by_zero_w | overflow_w;
        end
    end

    // --- Writeback Result Logic ---
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            wb_result_q <= 32'h0;
        end else if (div_complete_w | div_by_zero_w | overflow_w) begin
            if (div_by_zero_w) begin
                wb_result_q <= div_operation_w ? 32'hFFFFFFFF : opcode_ra_operand_i;
            end else if (overflow_w & div_operation_w) begin
                wb_result_q <= 32'h80000000;
            end else begin
                wb_result_q <= div_inst_q ? 
                              (invert_res_q ? ~quotient_q + 1 : quotient_q) :
                              (invert_res_q ? ~dividend_q + 1 : dividend_q);
            end
        end
    end

    // --- Outputs ---
    assign writeback_valid_o = valid_q;
    assign writeback_value_o = wb_result_q;

endmodule
