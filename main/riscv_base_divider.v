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

    // ========== INSTRUCTION DECODING ==========
    wire inst_div_w  = (opcode_opcode_i & `INST_DIV_MASK) == `INST_DIV;    // Chia có dấu
    wire inst_divu_w = (opcode_opcode_i & `INST_DIVU_MASK) == `INST_DIVU;  // Chia không dấu
    wire inst_rem_w  = (opcode_opcode_i & `INST_REM_MASK) == `INST_REM;    // Dư có dấu
    wire inst_remu_w = (opcode_opcode_i & `INST_REMU_MASK) == `INST_REMU;  // Dư không dấu

    wire div_rem_inst_w = inst_div_w | inst_divu_w | inst_rem_w | inst_remu_w;
    wire signed_operation_w = inst_div_w | inst_rem_w;
    wire div_operation_w = inst_div_w | inst_divu_w;

    // ========== SPECIAL CASES DETECTION ==========
    wire div_by_zero_w = (opcode_rb_operand_i == 32'h0);
    wire overflow_w = signed_operation_w & 
                      (opcode_ra_operand_i == 32'h80000000) & 
                      (opcode_rb_operand_i == 32'hFFFFFFFF);

    // ========== CONTROL SIGNALS ==========
    wire valid_div_req_w = opcode_valid_i & div_rem_inst_w & ~opcode_invalid_i;
    wire div_start_w = valid_div_req_w & ~div_by_zero_w & ~overflow_w & ~div_busy_q;
    wire special_case_w = valid_div_req_w & (div_by_zero_w | overflow_w);
    wire div_complete_w = (cycle_counter_q == 5'd0) & div_busy_q;

    // ========== SIGN PROCESSING ==========
    wire dividend_negative_w = signed_operation_w & opcode_ra_operand_i[31];
    wire divisor_negative_w = signed_operation_w & opcode_rb_operand_i[31];
    wire result_negative_w = signed_operation_w & 
                             ((div_operation_w & (opcode_ra_operand_i[31] ^ opcode_rb_operand_i[31])) |
                              (~div_operation_w & opcode_ra_operand_i[31])); // REM takes sign of dividend

    // Two's complement conversion
    wire [31:0] dividend_abs_w = dividend_negative_w ? (~opcode_ra_operand_i + 1'b1) : opcode_ra_operand_i;
    wire [31:0] divisor_abs_w = divisor_negative_w ? (~opcode_rb_operand_i + 1'b1) : opcode_rb_operand_i;

    // ========== STATE REGISTERS ==========
    reg [31:0] remainder_q;     // Current remainder
    reg [31:0] quotient_q;      // Current quotient
    reg [31:0] divisor_q;       // Divisor (constant)
    reg [5:0]  cycle_counter_q; // Bit counter (32 down to 1)
    reg        div_busy_q;      // Division in progress
    reg        div_inst_q;      // 1=DIV/DIVU, 0=REM/REMU
    reg        invert_result_q; // Need to negate final result
    reg        valid_q;         // Output valid signal
    reg [31:0] result_q;        // Final result

    // ========== DIVISION BUSY FLAG ==========
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            div_busy_q <= 1'b0;
        end else begin
            if (div_start_w) begin
                div_busy_q <= 1'b1;
            end else if (div_complete_w) begin
                div_busy_q <= 1'b0;
            end
        end
    end

    // ========== CYCLE COUNTER ==========
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            cycle_counter_q <= 6'd0;
        end else begin
            if (div_start_w) begin
                cycle_counter_q <= 6'd32; // Count 32 cycles
            end else if (div_busy_q & (cycle_counter_q != 6'd0)) begin
                cycle_counter_q <= cycle_counter_q - 1'b1;
            end
        end
    end

    // ========== OPERATION TYPE REGISTER ==========
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            div_inst_q <= 1'b0;
        end else begin
            if (div_start_w) begin
                div_inst_q <= div_operation_w;
            end
        end
    end

    // ========== RESULT SIGN REGISTER ==========
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            invert_result_q <= 1'b0;
        end else begin
            if (div_start_w) begin
                invert_result_q <= result_negative_w & |opcode_rb_operand_i;
            end
        end
    end

    // ========== DIVISOR REGISTER ==========
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            divisor_q <= 32'h0;
        end else begin
            if (div_start_w) begin
                divisor_q <= divisor_abs_w;
            end
        end
    end

    // ========== RESTORING DIVISION ALGORITHM ==========
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            remainder_q <= 32'h0;
            quotient_q <= 32'h0;
        end else begin
            if (div_start_w) begin
                remainder_q <= 32'h0;
                quotient_q <= dividend_abs_w;  // Load dividend into quotient initially
            end else if (div_busy_q & (cycle_counter_q != 5'd0)) begin
                // Shift remainder and quotient left
                remainder_q <= {remainder_q[30:0], quotient_q[31]};
                quotient_q <= quotient_q << 1;
                
                // Try subtraction
                if ({1'b0, remainder_q[30:0], quotient_q[31]} >= {1'b0, divisor_q}) begin
                    remainder_q <= {remainder_q[30:0], quotient_q[31]} - divisor_q;
                    quotient_q[0] <= 1'b1;  // Set LSB of quotient
                end else begin
                    quotient_q[0] <= 1'b0;  // Clear LSB of quotient
                end
            end
        end
    end

    // ========== OUTPUT VALID FLAG ==========
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            valid_q <= 1'b0;
        end else begin
            if (div_complete_w | special_case_w) begin
                valid_q <= 1'b1;
            end else if (valid_q & ~opcode_valid_i) begin
                valid_q <= 1'b0;
            end
        end
    end

    // ========== RESULT CALCULATION ==========
    wire [31:0] final_quotient_w = invert_result_q ? (~quotient_q + 1'b1) : quotient_q;
    wire [31:0] final_remainder_w = invert_result_q ? (~remainder_q + 1'b1) : remainder_q;

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            result_q <= 32'h0;
        end else begin
            if (div_complete_w) begin
                result_q <= div_inst_q ? final_quotient_w : final_remainder_w;
            end else if (special_case_w) begin
                if (div_by_zero_w) begin
                    result_q <= div_operation_w ? 32'hFFFFFFFF : opcode_ra_operand_i;
                end else if (overflow_w) begin
                    result_q <= div_operation_w ? 32'h80000000 : 32'h0;
                end
            end
        end
    end

    // ========== OUTPUT ASSIGNMENTS ==========
    assign writeback_valid_o = valid_q;
    assign writeback_value_o = result_q;

endmodule