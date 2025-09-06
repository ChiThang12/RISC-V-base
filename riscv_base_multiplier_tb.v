`timescale 1ns/1ps
`include "riscv_base_defines.v"
`include "riscv_base_multiplier.v"
module riscv_base_multiplier_tb();

    reg clk;
    reg rst;
    reg hold;

    reg          opcode_valid;
    reg [31:0]   opcode_opcode;
    reg [31:0]   opcode_pc;
    reg          opcode_invalid;

    reg [4:0]    opcode_rd_idx;
    reg [4:0]    opcode_ra_idx;
    reg [4:0]    opcode_rb_idx;

    reg [31:0]   opcode_ra_operand;
    reg [31:0]   opcode_rb_operand;

    wire [31:0]  writeback_value;

    // DUT
    riscv_base_multiplier dut (
        .clk_i(clk),
        .rst_i(rst),
        .hold_i(hold),
        .opcode_valid_i(opcode_valid),
        .opcode_opcode_i(opcode_opcode),
        .opcode_pc_i(opcode_pc),
        .opcode_invalid_i(opcode_invalid),
        .opcode_rd_idx_i(opcode_rd_idx),
        .opcode_ra_idx_i(opcode_ra_idx),
        .opcode_rb_idx_i(opcode_rb_idx),
        .opcode_ra_operand_i(opcode_ra_operand),
        .opcode_rb_operand_i(opcode_rb_operand),
        .writeback_value_o(writeback_value)
    );

    // clock
    always #5 clk = ~clk;

    // reference model
    function [31:0] ref_mul;
        input [31:0] a;
        input [31:0] b;
        input [31:0] opcode;

        reg [63:0] tmp;
    begin
        if ((opcode & `INST_MUL_MASK) == `INST_MUL) begin
            tmp = $signed(a) * $signed(b);
            ref_mul = tmp[31:0];
        end
        else if ((opcode & `INST_MULH_MASK) == `INST_MULH) begin
            tmp = $signed(a) * $signed(b);
            ref_mul = tmp[63:32];
        end
        else if ((opcode & `INST_MULHSU_MASK) == `INST_MULHSU) begin
            tmp = $signed(a) * b; // b treated as unsigned
            ref_mul = tmp[63:32];
        end
        else if ((opcode & `INST_MULHU_MASK) == `INST_MULHU) begin
            tmp = a * b; // both unsigned
            ref_mul = tmp[63:32];
        end
        else begin
            ref_mul = 32'h0;
        end
    end
    endfunction


    initial begin
        $dumpfile("riscv_base_multiplier_tb.vcd");
        $dumpvars(0, riscv_base_multiplier_tb);
    end

    // task test
    task run_case;
        input [31:0] op_a;
        input [31:0] op_b;
        input [31:0] opcode;
        reg [31:0] exp;
    begin
        @(negedge clk);
        opcode_ra_operand = op_a;
        opcode_rb_operand = op_b;
        opcode_opcode     = opcode;
        opcode_valid      = 1;
        opcode_invalid    = 0;
        hold              = 0;

        exp = ref_mul(op_a, op_b, opcode);

        // đợi pipeline 2 stage
        repeat(3) @(negedge clk);

        if (writeback_value !== exp) begin
            $display("FAIL: opcode=%h a=%0d b=%0d => got=%h expected=%h",
                     opcode, op_a, op_b, writeback_value, exp);
        end else begin
            $display("PASS: opcode=%h a=%0d b=%0d => result=%h",
                     opcode, op_a, op_b, writeback_value);
        end
    end
    endtask

    initial begin
        clk = 0; rst = 1; hold = 0;
        opcode_valid = 0; opcode_invalid = 0;
        opcode_opcode = 0;
        opcode_pc = 0;
        opcode_rd_idx = 0;
        opcode_ra_idx = 0;
        opcode_rb_idx = 0;
        opcode_ra_operand = 0;
        opcode_rb_operand = 0;

        #20 rst = 0;

        // Testcases
        run_case(32'd5, 32'd7, `INST_MUL);         // MUL
        run_case(-32'd8, 32'd3, `INST_MUL);        // MUL signed
        run_case(-32'd8, 32'd3, `INST_MULH);       // MULH
        run_case(-32'd8, 32'd3, `INST_MULHSU);     // MULHSU

        #1000;
        $finish;
    end

endmodule
