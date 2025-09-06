`timescale 1ns/1ps
`include "riscv_base_defines.v"
`include "riscv_base_alu.v"

module riscv_base_alu_tb();

    // Khai bao cac tin hieu de kiem tra
    reg [3:0]   alu_op_i;    // Tin hieu chon phep toan ALU
    reg [31:0]  alu_a_i;     // Toan hang dau vao A
    reg [31:0]  alu_b_i;     // Toan hang dau vao B  
    wire [31:0] alu_res_o;   // Ket qua dau ra

    // Khoi tao doi tuong kiem tra (Unit Under Test)
    riscv_base_alu uut (
        .alu_op_i(alu_op_i),
        .alu_a_i(alu_a_i), 
        .alu_b_i(alu_b_i),
        .alu_res_o(alu_res_o)
    );

    // Khoi kiem tra cac truong hop
    initial begin
        $dumpfile("riscv_base_alu_tb.vcd");  // Tao file luu ket qua song
        $dumpvars(0, riscv_base_alu_tb);

        // Kiem tra phep cong: 5 + 3 = 8
        #10; // Doi 10ns
        alu_op_i = `ALU_ADD;
        alu_a_i = 32'h5;  // So 5 he hex
        alu_b_i = 32'h3;  // So 3 he hex
        #10;
        if(alu_res_o !== 32'h8) $display("Loi phep cong: %h + %h = %h", alu_a_i, alu_b_i, alu_res_o);

        // Kiem tra phep tru: 8 - 3 = 5 
        #10;
        alu_op_i = `ALU_SUB;
        alu_a_i = 32'h8;
        alu_b_i = 32'h3;  
        #10;
        if(alu_res_o !== 32'h5) $display("Loi phep tru: %h - %h = %h", alu_a_i, alu_b_i, alu_res_o);

        // Kiem tra dich trai: 1 << 1 = 2
        #10;
        alu_op_i = `ALU_SHIFT_LEFT;
        alu_a_i = 32'h1;
        alu_b_i = 32'h1;  // Dich trai 1 bit
        #10;
        if(alu_res_o !== 32'h2) $display("Loi dich trai: %h << %h = %h", alu_a_i, alu_b_i, alu_res_o);

        // Kiem tra dich phai so hoc voi so am
        #10;
        alu_op_i = `ALU_SHIFT_RIGHT_ARITHMETIC;
        alu_a_i = 32'h80000000;  // So am lon nhat -2^31
        alu_b_i = 32'h1;          // Dich phai 1 bit
        #10;
        if(alu_res_o !== 32'hC0000000) $display("Loi dich phai so hoc: %h >>> %h = %h", alu_a_i, alu_b_i, alu_res_o);

        // Kiem tra phep AND: F & 3 = 3
        #10;
        alu_op_i = `ALU_AND;
        alu_a_i = 32'hF;    // 1111
        alu_b_i = 32'h3;    // 0011
        #10;
        if(alu_res_o !== 32'h3) $display("Loi phep AND: %h & %h = %h", alu_a_i, alu_b_i, alu_res_o);

        // Kiem tra so sanh so co dau: -1 < 1 = true(1)
        #10;
        alu_op_i = `ALU_LESS_THAN_UNSIGNED;
        alu_a_i = 32'hFFFFFFFF;  // -1 
        alu_b_i = 32'h1;          // 1
        #10;
        if(alu_res_o !== 32'h1) $display("Loi so sanh co dau: %h < %h = %h", alu_a_i, alu_b_i, alu_res_o);

        #10;
        $display("Hoan thanh kiem tra!");
        $finish;
    end

    // Theo doi va hien thi cac thay doi
    initial begin
        $monitor("Thoi gian=%0d op=%b a=%h b=%h ket qua=%h", 
                 $time, alu_op_i, alu_a_i, alu_b_i, alu_res_o);
    end

endmodule
