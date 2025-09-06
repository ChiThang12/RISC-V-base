module riscv_base_divider(

    input           clk_i,
    input           rst_i,
    input           opcode_valid_i,     // báo hiệu lệnh đầu vào hợp lệ, bắt đầu chia
    input  [ 31:0]  opcode_opcode_i,    
    input  [ 31:0]  opcode_pc_i,        
    input           opcode_invalid_i,   // Báo hiệu lệnh đầu vào không hợp lệ

    input  [  4:0]  opcode_rd_idx_i,    //Chỉ số thanh ghi đích (rd), nơi ghi kết quả phép chia/rem.
    input  [  4:0]  opcode_ra_idx_i,    
    input  [  4:0]  opcode_rb_idx_i,    
    
    input  [ 31:0]  opcode_ra_operand_i,//(dividend).
    input  [ 31:0]  opcode_rb_operand_i,//(divisor).

    // Outputs
    output          writeback_valid_o,  //Báo hiệu kết quả phép chia đã sẵn sàng để ghi về thanh ghi đích.
    output [ 31:0]  writeback_value_o   

);
    `include "riscv_base_defines.v"

    reg         valid_q;
    reg [31:0]  wb_result_q;

    // DIV (chia có dấu), DIVU (chia không dấu), REM (lấy dư có dấu), REMU (lấy dư không dấu)
    // (A&B) = C sẽ trả về kết quả 0 hoặc 1

    wire inst_div_w         = (opcode_opcode_i & `INST_DIV_MASK) == `INST_DIV;
    wire inst_divu_w        = (opcode_opcode_i & `INST_DIVU_MASK) == `INST_DIVU;
    wire inst_rem_w         = (opcode_opcode_i & `INST_REM_MASK) == `INST_REM;
    wire inst_remu_w        = (opcode_opcode_i & `INST_REMU_MASK) == `INST_REMU;


    wire div_rem_inst_w     = ((opcode_opcode_i & `INST_DIV_MASK) == `INST_DIV)  || 
                            ((opcode_opcode_i & `INST_DIVU_MASK) == `INST_DIVU) ||
                            ((opcode_opcode_i & `INST_REM_MASK) == `INST_REM)  ||
                            ((opcode_opcode_i & `INST_REMU_MASK) == `INST_REMU);

      // có dấu
    wire signed_operation_w = ((opcode_opcode_i & `INST_DIV_MASK) == `INST_DIV) || ((opcode_opcode_i & `INST_REM_MASK) == `INST_REM);
    // chia không có dư
    wire div_operation_w    = ((opcode_opcode_i & `INST_DIV_MASK) == `INST_DIV) || ((opcode_opcode_i & `INST_DIVU_MASK) == `INST_DIVU);

    reg [31:0] dividend_q // so bi chia
    reg [62:0] divisor_q  // so chia
    reg [31:0] quotient_q // thuong
    reg [31:0] q_mask_q;
    reg        div_inst_q; //1/0: DIV_DIVU/REM_REMU
    reg        div_busy_q; // 1/0: dang chia
    reg        invert_res_q;// Bao hieu can dao dau ket qua

    wire div_start_w = opcode_valid_i & div_rem_inst_w;
    wire div_complete_w = !(|q_mask_q == 0) & div_busy_q;

    always @(posedge clk_i or posedge rst_i) begin
        if(rst_i) begin
            div_busy_q     <= 1'b0;
            dividend_q     <= 32'b0;
            divisor_q      <= 63'b0;
            invert_res_q   <= 1'b0;
            quotient_q     <= 32'b0;
            q_mask_q       <= 32'b0;
            div_inst_q     <= 1'b0;
        end
        else if(div_start_w) begin
            div_busy_q <= 1'b1;
            div_inst_q <= div_operation_w;

            if(signed_operation_w && opcode_ra_operand_i[31])
                dividend_q <= -opcode_ra_operand_i;
            else
                dividend_q <= opcode_ra_operand_i;

            if(signed_operation_w && opcode_rb_operand_i[31])
                divisor_q <= {-opcode_rb_operand_i, 31'b0};
            else
                divisor_q <= {opcode_rb_operand_i, 31'b0};

            invert_res_q  <= (((opcode_opcode_i & `INST_DIV_MASK) == `INST_DIV) && (opcode_ra_operand_i[31] != opcode_rb_operand_i[31]) && |opcode_rb_operand_i) || 
                        (((opcode_opcode_i & `INST_REM_MASK) == `INST_REM) && opcode_ra_operand_i[31]);

            quotient_q <= 32'b0;
            q_mask_q   <= 32'h8000_0000;

        end
        else if(div_complete_w) begin
            div_busy_q <= 1'b0;
        end 
        else if(div_busy_q) begin
            if(divisor_q <= {31'b0,dividend_q}) begin
                dividend_q <= dividend_q - divisor_q[31:0];
                quotient_q <= quotient_q | q_mask_q;
            end
            divisor_q <= {1'b0, divisor_q[62:1]};
            q_mask_q <= {1'b0, q_mask_q[31:1]};
        end
    end

    reg [31:0] div_result_r;

    always @(*) begin
        div_result_r = 32'b0;
        if(div_inst_q) 
            div_result_r = invert_res_q ? -quotient_q : quotient_q;
        else
            div_result_r = invert_res_q ? -dividend_q : dividend_q;
    end

    always @(posedge clk_i or posedge rst_i) begin
        if(rst_i) 
            valid_q <= 1'b0;
        else
            valid_q <= div_complete_w;
    end

    always @(posedge clk_i or posedge rst_i) begin
        if(rst_i) 
            wb_result_q <= 32'b0;
        else if(div_complete_w)
            wb_result_q <= div_result_r;
    end

    assign writeback_valid_o = valid_q;
    assign writeback_value_o = wb_result_q;

endmodule