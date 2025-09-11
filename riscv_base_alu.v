`include "riscv_base_defines.v"
module riscv_base_alu(
    input  [3:0] alu_op_i,
    input  [31:0] alu_a_i,
    input  [31:0] alu_b_i,

    output [31:0] alu_res_o
);


    reg [31:0] result_r;

    // Thanh ghi hỗ trợ dịch phải
    reg [31:16]   shift_right_fill_r;
    reg [31:0]    shift_right_1_r; //2^0
    reg [31:0]    shift_right_2_r; //2^1
    reg [31:0]    shift_right_4_r; //2^2
    reg [31:0]    shift_right_8_r; //2^3

    // Thanh ghi hỗ trợ dịch trái
    reg [31:0]   shift_left_1_r; //2^0
    reg [31:0]   shift_left_2_r; //2^1
    reg [31:0]   shift_left_4_r; //2^2
    reg [31:0]   shift_left_8_r; //2^3

//-----------------------------------------------------------------
//                              ALU
//-----------------------------------------------------------------
// Phép trừ
    wire [31:0]   sub_result_w = alu_a_i - alu_b_i;

    always @(alu_op_i or alu_a_i or alu_b_i or sub_result_w) begin
        shift_right_fill_r = 16'b0;
        shift_right_1_r = 31'b0;
        shift_right_2_r= 31'b0;
        shift_right_4_r = 31'b0;
        shift_right_8_r = 31'b0;

        shift_left_1_r = 31'b0;
        shift_left_2_r = 31'b0;
        shift_left_4_r = 31'b0;
        shift_left_8_r = 31'b0;
        

        case (alu_op_i)

            `ALU_SHIFTL:
            begin
                //        Bit	Dịch bao nhiêu	Ghi chú
                // alu_b_i[0]	1 bit	        dịch nếu bit 0 = 1
                // alu_b_i[1]	2 bit	        dịch nếu bit 1 = 1
                // alu_b_i[2]	4 bit	        dịch nếu bit 2 = 1
                // alu_b_i[3]	8 bit	        dịch nếu bit 3 = 1
                // alu_b_i[4]	16 bit	        dịch nếu bit 4 = 1
                if(alu_b_i[0] == 1'b1) 
                    shift_left_1_r = {alu_a_i[30:0], 1'b0};
                else 
                    shift_left_1_r = alu_a_i;

                if(alu_b_i[1] == 1'b1)
                    shift_left_2_r = {shift_left_1_r[29:0], 2'b00};
                else 
                    shift_left_2_r = shift_left_1_r;

                if(alu_b_i[2] == 1'b1)
                    shift_left_4_r = {shift_left_2_r[27:0], 4'b0000};
                else 
                    shift_left_4_r = shift_left_2_r;
                
                if(alu_b_i[3] == 1'b1)
                    shift_left_8_r = {shift_left_4_r[23:0], 8'b00000000};
                else 
                    shift_left_8_r = shift_left_4_r;

                if(alu_b_i[4] == 1'b1)
                    result_r = {shift_left_8_r[15:0], 16'b0000000000000000};
                else 
                    result_r = shift_left_8_r;
            end

            `ALU_SHIFTR, `ALU_SHIFTR_ARITH: begin
            // Dịch phải sẽ dính bit dấu
                //        Bit	Dịch bao nhiêu	Ghi chú
                // alu_b_i[0]	1 bit	        dịch nếu bit 0 = 1
                // alu_b_i[1]	2 bit	        dịch nếu bit 1 = 1
                // alu_b_i[2]	4 bit	        dịch nếu bit 2 = 1
                // alu_b_i[3]	8 bit	        dịch nếu bit 3 = 1
                // alu_b_i[4]	16 bit	        dịch nếu bit 4 = 1
                if(alu_a_i[31]==1'b1 && alu_op_i == `ALU_SHIFTR_ARITH)
                    shift_right_fill_r = 16'b1111111111111111;
                else 
                    shift_right_fill_r = 16'b0000000000000000;

                if(alu_b_i[0] == 1'b1)
                    shift_right_1_r = {shift_right_fill_r[31], alu_a_i[31:1]};
                else 
                    shift_right_1_r = alu_a_i;
                
                if(alu_b_i[1] == 1'b1)
                    shift_right_2_r = {shift_right_fill_r[31:30], shift_right_1_r[31:2]};
                else    
                    shift_right_2_r = shift_right_1_r;

                if(alu_b_i[2] == 1'b1)
                    shift_right_4_r = {shift_right_fill_r[31:28], shift_right_2_r[31:4]};
                else 
                    shift_right_4_r = shift_right_2_r;
                
                if(alu_b_i[3] == 1'b1)
                    shift_right_8_r = {shift_right_fill_r[31:24], shift_right_4_r[31:8]};
                else 
                    shift_right_8_r = shift_right_4_r;
                
                if(alu_b_i[4] == 1'b1)
                    result_r = {shift_right_fill_r[31:16], shift_right_8_r[31:16]};
                else 
                    result_r = shift_right_8_r;
            end


            // Bộ cộng
            `ALU_ADD: begin
                result_r = alu_a_i + alu_b_i;
            end

            // Bộ trừ
            `ALU_SUB: begin
                result_r = sub_result_w;
            end

            // Phép AND
            `ALU_AND: begin
                result_r = alu_a_i & alu_b_i;
            end

            // Phép OR
            `ALU_OR: begin
                result_r = alu_a_i | alu_b_i;
            end

            // Phép XOR
            `ALU_XOR: begin
                result_r = alu_a_i ^ alu_b_i;
            end

            // Phép so sánh (signed)
            `ALU_LESS_THAN: begin
                result_r =(alu_a_i < alu_b_i) ? 32'h1 : 32'h0;
            end

            `ALU_LESS_THAN_SIGNED: begin
                if(alu_a_i[31] != alu_b_i[31]) 
                    result_r = alu_a_i[31] ? 32'h1 : 32'h0; // a âm, b dương => a < b
                else 
                    result_r = sub_result_w[31] ? 32'h1 : 32'h0; // cùng dấu => so sánh bình thường (dungf phep tru)
            end
            default : begin
                result_r = alu_a_i;
            end
        endcase
    end

    assign alu_res_o = result_r;

endmodule