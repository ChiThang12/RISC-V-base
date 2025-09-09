
`timescale 1ns / 1ps
`include "riscv_base_defines.v"
`include "riscv_base_divider.v"
module riscv_base_divider_tb;

    // Inputs
    reg           clk_i;
    reg           rst_i;
    reg           opcode_valid_i;
    reg           opcode_invalid_i;
    reg [31:0]    opcode_opcode_i;
    reg [31:0]    opcode_pc_i;
    reg [4:0]     opcode_rd_idx_i;
    reg [4:0]     opcode_ra_idx_i;
    reg [4:0]     opcode_rb_idx_i;
    reg [31:0]    opcode_ra_operand_i;
    reg [31:0]    opcode_rb_operand_i;

    // Outputs
    wire          writeback_valid_o;
    wire [31:0]   writeback_value_o;

    // Instantiate the Unit Under Test (UUT)
    riscv_base_divider uut (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .opcode_valid_i(opcode_valid_i),
        .opcode_invalid_i(opcode_invalid_i),
        .opcode_opcode_i(opcode_opcode_i),
        .opcode_pc_i(opcode_pc_i),
        .opcode_rd_idx_i(opcode_rd_idx_i),
        .opcode_ra_idx_i(opcode_ra_idx_i),
        .opcode_rb_idx_i(opcode_rb_idx_i),
        .opcode_ra_operand_i(opcode_ra_operand_i),
        .opcode_rb_operand_i(opcode_rb_operand_i),
        .writeback_valid_o(writeback_valid_o),
        .writeback_value_o(writeback_value_o)
    );

    // Clock generation: 50MHz (20ns period)
    initial begin
        clk_i = 0;
        forever #10 clk_i = ~clk_i; // 20ns clock period
    end

    // Test stimulus
    initial begin
        // Initialize inputs
        rst_i = 1;
        opcode_valid_i = 0;
        opcode_invalid_i = 0;
        opcode_opcode_i = 32'h0;
        opcode_pc_i = 32'h0;
        opcode_rd_idx_i = 5'h0;
        opcode_ra_idx_i = 5'h0;
        opcode_rb_idx_i = 5'h0;
        opcode_ra_operand_i = 32'h0;
        opcode_rb_operand_i = 32'h0;

        // Reset
        #40 rst_i = 0;

        // Test case 0: Idle state
        #40;
        $display("Test case 0: Idle state");
        $display("Time=%0t rst=%b valid=%b op=%h a=%h b=%h wb_valid=%b wb_value=%h",
                 $time, rst_i, opcode_valid_i, opcode_opcode_i,
                 opcode_ra_operand_i, opcode_rb_operand_i,
                 writeback_valid_o, writeback_value_o);

        // Test case 1: DIV 15 / 3 (expect 0x5)
        #40;
        opcode_valid_i = 1;
        opcode_opcode_i = 32'h02004033; // DIV
        opcode_ra_operand_i = 32'h0000000F; // 15
        opcode_rb_operand_i = 32'h00000003; // 3
        $display("Test case 1: DIV 15 / 3");
        #700; // Wait for division (32 cycles + margin)
        opcode_valid_i = 0;
        #20;
        $display("Result: wb_valid=%b wb_value=%h (expect 0x5)", writeback_valid_o, writeback_value_o);

        // Test case 2: DIV -15 / 3 (expect 0xFFFFFFFB)
        #40;
        opcode_valid_i = 1;
        opcode_opcode_i = 32'h02004033; // DIV
        opcode_ra_operand_i = 32'hFFFFFFF1; // -15
        opcode_rb_operand_i = 32'h00000003; // 3
        $display("Test case 2: DIV -15 / 3");
        #700;
        opcode_valid_i = 0;
        #20;
        $display("Result: wb_valid=%b wb_value=%h (expect 0xFFFFFFFB)", writeback_valid_o, writeback_value_o);

        // Test case 3: REM 15 / 3 (expect 0x0)
        #40;
        opcode_valid_i = 1;
        opcode_opcode_i = 32'h02006033; // REM
        opcode_ra_operand_i = 32'h0000000F; // 15
        opcode_rb_operand_i = 32'h00000003; // 3
        $display("Test case 3: REM 15 / 3");
        #700;
        opcode_valid_i = 0;
        #20;
        $display("Result: wb_valid=%b wb_value=%h (expect 0x0)", writeback_valid_o, writeback_value_o);

        // Test case 4: DIVU 15 / 3 (expect 0x5)
        #40;
        opcode_valid_i = 1;
        opcode_opcode_i = 32'h02005033; // DIVU
        opcode_ra_operand_i = 32'h0000000F; // 15
        opcode_rb_operand_i = 32'h00000003; // 3
        $display("Test case 4: DIVU 15 / 3");
        #700;
        opcode_valid_i = 0;
        #20;
        $display("Result: wb_valid=%b wb_value=%h (expect 0x5)", writeback_valid_o, writeback_value_o);

        // Test case 5: REMU 15 / 3 (expect 0x0)
        #40;
        opcode_valid_i = 1;
        opcode_opcode_i = 32'h02007033; // REMU
        opcode_ra_operand_i = 32'h0000000F; // 15
        opcode_rb_operand_i = 32'h00000003; // 3
        $display("Test case 5: REMU 15 / 3");
        #700;
        opcode_valid_i = 0;
        #20;
        $display("Result: wb_valid=%b wb_value=%h (expect 0x0)", writeback_valid_o, writeback_value_o);

        // Test case 6: DIV 15 / 0 (expect 0xFFFFFFFF)
        #40;
        opcode_valid_i = 1;
        opcode_opcode_i = 32'h02004033; // DIV
        opcode_ra_operand_i = 32'h0000000F; // 15
        opcode_rb_operand_i = 32'h00000000; // 0
        $display("Test case 6: DIV 15 / 0");
        #700;
        opcode_valid_i = 0;
        #20;
        $display("Result: wb_valid=%b wb_value=%h (expect 0xFFFFFFFF)", writeback_valid_o, writeback_value_o);

        // Test case 7: REM 15 / 0 (expect 0x0000000F)
        #40;
        opcode_valid_i = 1;
        opcode_opcode_i = 32'h02006033; // REM
        opcode_ra_operand_i = 32'h0000000F; // 15
        opcode_rb_operand_i = 32'h00000000; // 0
        $display("Test case 7: REM 15 / 0");
        #700;
        opcode_valid_i = 0;
        #20;
        $display("Result: wb_valid=%b wb_value=%h (expect 0x0000000F)", writeback_valid_o, writeback_value_o);

        // Test case 8: DIV 0x80000000 / -1 (expect 0x80000000)
        #40;
        opcode_valid_i = 1;
        opcode_opcode_i = 32'h02004033; // DIV
        opcode_ra_operand_i = 32'h80000000; // -2^31
        opcode_rb_operand_i = 32'hFFFFFFFF; // -1
        $display("Test case 8: DIV 0x80000000 / -1");
        #700;
        opcode_valid_i = 0;
        #20;
        $display("Result: wb_valid=%b wb_value=%h (expect 0x80000000)", writeback_valid_o, writeback_value_o);

        // Test case 9: Invalid opcode
        #40;
        opcode_valid_i = 0;
        opcode_invalid_i = 1;
        opcode_opcode_i = 32'h02004033; // DIV (but invalid)
        opcode_ra_operand_i = 32'h80000000;
        opcode_rb_operand_i = 32'hFFFFFFFF;
        $display("Test case 9: Invalid opcode");
        #700;
        opcode_valid_i = 0;
        opcode_invalid_i = 0;
        #20;
        $display("Result: wb_valid=%b wb_value=%h (expect wb_valid=0, wb_value=0x00000000)",
                 writeback_valid_o, writeback_value_o);

        // Additional test case: DIV -15 / -3 (expect 0x5)
        #40;
        opcode_valid_i = 1;
        opcode_opcode_i = 32'h02004033; // DIV
        opcode_ra_operand_i = 32'hFFFFFFF1; // -15
        opcode_rb_operand_i = 32'hFFFFFFFD; // -3
        $display("Test case 10: DIV -15 / -3");
        #700;
        opcode_valid_i = 0;
        #20;
        $display("Result: wb_valid=%b wb_value=%h (expect 0x5)", writeback_valid_o, writeback_value_o);

        // End simulation
        #100;
        $display("All tests completed!");
        $finish;
    end

    // Monitor for debugging
    initial begin
        $monitor("Time=%0t rst=%b valid=%b op=%h a=%h b=%h wb_valid=%b wb_value=%h",
                 $time, rst_i, opcode_valid_i, opcode_opcode_i,
                 opcode_ra_operand_i, opcode_rb_operand_i,
                 writeback_valid_o, writeback_value_o);
    end

endmodule
