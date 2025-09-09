`timescale 1ns/1ps
`include "riscv_base_defines.v"
`include "riscv_base_multiplier.v"

module riscv_base_multiplier_tb;
    reg         clk_i;
    reg         rst_i;
    reg         opcode_valid_i;
    reg  [31:0] opcode_opcode_i;
    reg  [31:0] opcode_pc_i;
    reg         opcode_invalid_i;
    reg  [4:0]  opcode_rd_idx_i;
    reg  [4:0]  opcode_ra_idx_i;
    reg  [4:0]  opcode_rb_idx_i;
    reg  [31:0] opcode_ra_operand_i;
    reg  [31:0] opcode_rb_operand_i;
    reg         hold_i;
    wire [31:0] writeback_value_o;

    // Khởi tạo module
    riscv_base_multiplier uut (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .opcode_valid_i(opcode_valid_i),
        .opcode_opcode_i(opcode_opcode_i),
        .opcode_pc_i(opcode_pc_i),
        .opcode_invalid_i(opcode_invalid_i),
        .opcode_rd_idx_i(opcode_rd_idx_i),
        .opcode_ra_idx_i(opcode_ra_idx_i),
        .opcode_rb_idx_i(opcode_rb_idx_i),
        .opcode_ra_operand_i(opcode_ra_operand_i),
        .opcode_rb_operand_i(opcode_rb_operand_i),
        .hold_i(hold_i),
        .writeback_value_o(writeback_value_o)
    );

    // Tạo xung nhịp
    initial begin
        clk_i = 0;
        forever #5 clk_i = ~clk_i; // Chu kỳ 10ns
    end

    // Tạo file VCD để debug
    initial begin
        $dumpfile("riscv_base_multiplier_tb.vcd");
        $dumpvars(0, riscv_base_multiplier_tb);
    end

    // Kịch bản kiểm tra
    initial begin
        // Khởi tạo các tín hiệu
        rst_i = 1;
        opcode_valid_i = 0;
        opcode_invalid_i = 0;
        hold_i = 0;
        opcode_opcode_i = 32'h0;
        opcode_pc_i = 32'h0;        // Khởi tạo tín hiệu không dùng
        opcode_rd_idx_i = 5'h0;
        opcode_ra_idx_i = 5'h0;
        opcode_rb_idx_i = 5'h0;
        opcode_ra_operand_i = 32'h0;
        opcode_rb_operand_i = 32'h0;
        #30; // Đợi 3 chu kỳ để đảm bảo reset ổn định
        rst_i = 0;
        #30; // Đợi thêm trước khi bắt đầu test

        // Test case 1: MUL - Số dương nhỏ (5 * 3)
        $display("\nTest case 1: MUL 5 * 3");
        opcode_valid_i = 1;
        opcode_opcode_i = `INST_MUL; // 02000033
        opcode_ra_operand_i = 32'h5;
        opcode_rb_operand_i = 32'h3;
        #30; // Đợi 3 chu kỳ để xử lý độ trễ
        if (writeback_value_o !== 32'hF)
            $display("Error: MUL 5 * 3 = %h (expect 0xF)", writeback_value_o);
        else
            $display("Pass: MUL 5 * 3 = %h", writeback_value_o);

        // Test case 2: MUL - Số âm * Số dương (-5 * 3)
        $display("\nTest case 2: MUL -5 * 3");
        opcode_ra_operand_i = -32'h5; // 0xFFFFFFFB
        opcode_rb_operand_i = 32'h3;
        #30;
        if (writeback_value_o !== -32'hF) // 0xFFFFFFF1
            $display("Error: MUL -5 * 3 = %h (expect 0xFFFFFFF1)", writeback_value_o);
        else
            $display("Pass: MUL -5 * 3 = %h", writeback_value_o);

        // Test case 3: MULH - Số âm * Số dương (-5 * 3)
        $display("\nTest case 3: MULH -5 * 3");
        opcode_opcode_i = `INST_MULH; // 02002033
        opcode_ra_operand_i = -32'h5;
        opcode_rb_operand_i = 32'h3;
        #30;
        if (writeback_value_o !== -32'h1) // 0xFFFFFFFF
            $display("Error: MULH -5 * 3 = %h (expect 0xFFFFFFFF)", writeback_value_o);
        else
            $display("Pass: MULH -5 * 3 = %h", writeback_value_o);

        // Test case 4: MULHSU - Số âm * Số dương không dấu (-5 * 3)
        $display("\nTest case 4: MULHSU -5 * 3");
        opcode_opcode_i = `INST_MULHSU; // 02003033
        opcode_ra_operand_i = -32'h5;
        opcode_rb_operand_i = 32'h3;
        #30;
        if (writeback_value_o !== 32'hFFFFFFFF)
            $display("Error: MULHSU -5 * 3 = %h (expect 0xFFFFFFFF)", writeback_value_o);
        else
            $display("Pass: MULHSU -5 * 3 = %h", writeback_value_o);

        // Test case 5: MULHU - Số không dấu lớn (0xFFFFFFFF * 2)
        $display("\nTest case 5: MULHU 0xFFFFFFFF * 2");
        opcode_opcode_i = `INST_MULHU; // 02003033
        opcode_ra_operand_i = 32'hFFFFFFFF;
        opcode_rb_operand_i = 32'h2;
        #30;
        if (writeback_value_o !== 32'h1)
            $display("Error: MULHU 0xFFFFFFFF * 2 = %h (expect 0x1)", writeback_value_o);
        else
            $display("Pass: MULHU 0xFFFFFFFF * 2 = %h", writeback_value_o);

        // Test case 6: MUL - Hai số âm (-5 * -3)
        $display("\nTest case 6: MUL -5 * -3");
        opcode_opcode_i = `INST_MUL;
        opcode_ra_operand_i = -32'h5; // 0xFFFFFFFB
        opcode_rb_operand_i = -32'h3; // 0xFFFFFFFD
        #30;
        if (writeback_value_o !== 32'hF) // 15
            $display("Error: MUL -5 * -3 = %h (expect 0xF)", writeback_value_o);
        else
            $display("Pass: MUL -5 * -3 = %h", writeback_value_o);

        // Test case 7: MUL - Nhân với 0 (0 * 5)
        $display("\nTest case 7: MUL 0 * 5");
        opcode_opcode_i = `INST_MUL;
        opcode_ra_operand_i = 32'h0;
        opcode_rb_operand_i = 32'h5;
        #30;
        if (writeback_value_o !== 32'h0)
            $display("Error: MUL 0 * 5 = %h (expect 0x0)", writeback_value_o);
        else
            $display("Pass: MUL 0 * 5 = %h", writeback_value_o);

        // Test case 8: MUL - Giá trị âm nhỏ nhất (0x80000000 * 1)
        $display("\nTest case 8: MUL 0x80000000 * 1");
        opcode_opcode_i = `INST_MUL;
        opcode_ra_operand_i = 32'h80000000; // -2^31
        opcode_rb_operand_i = 32'h1;
        #30;
        if (writeback_value_o !== 32'h80000000)
            $display("Error: MUL 0x80000000 * 1 = %h (expect 0x80000000)", writeback_value_o);
        else
            $display("Pass: MUL 0x80000000 * 1 = %h", writeback_value_o);

        // Test case 9: Kiểm tra tín hiệu hold
        $display("\nTest case 9: Testing hold signal");
        opcode_opcode_i = `INST_MUL;
        opcode_ra_operand_i = 32'h5;
        opcode_rb_operand_i = 32'h3;
        hold_i = 1;
        #30;
        if (writeback_value_o !== 32'h0) // Giả sử hold giữ output ở 0
            $display("Error: Hold active, expected 0x0, got %h", writeback_value_o);
        else
            $display("Pass: Hold active, output = %h", writeback_value_o);
        hold_i = 0;
        #30;
        if (writeback_value_o !== 32'hF)
            $display("Error: Hold released, MUL 5 * 3 = %h (expect 0xF)", writeback_value_o);
        else
            $display("Pass: Hold released, MUL 5 * 3 = %h", writeback_value_o);

        // Test case 10: Kiểm tra opcode không hợp lệ
        $display("\nTest case 10: Testing invalid opcode");
        opcode_invalid_i = 1;
        opcode_valid_i = 0; // Đảm bảo valid=0 khi invalid=1
        #30;
        if (writeback_value_o !== 32'h0)
            $display("Error: Invalid opcode, expected 0x0, got %h", writeback_value_o);
        else
            $display("Pass: Invalid opcode, output = %h", writeback_value_o);

        // Kết thúc test
        #20;
        $display("\nAll tests completed!");
        $finish;
    end

    // Monitor kết quả
    initial begin
        $monitor("Time=%0d rst=%b valid=%b op=%h a=%h b=%h result=%h",
            $time, rst_i, opcode_valid_i, opcode_opcode_i,
            opcode_ra_operand_i, opcode_rb_operand_i, writeback_value_o);
    end
endmodule