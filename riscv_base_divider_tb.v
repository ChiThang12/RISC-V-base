`timescale 1ns / 1ps

`include "riscv_base_defines.v"
`include "riscv_base_divider.v"


module riscv_base_divider_tb;
    // ========== TESTBENCH SIGNALS ==========
    reg         clk_i;
    reg         rst_i;
    reg         opcode_valid_i;
    reg [31:0]  opcode_opcode_i;
    reg [31:0]  opcode_pc_i;
    reg         opcode_invalid_i;
    reg [4:0]   opcode_rd_idx_i;
    reg [4:0]   opcode_ra_idx_i;
    reg [4:0]   opcode_rb_idx_i;
    reg [31:0]  opcode_ra_operand_i;
    reg [31:0]  opcode_rb_operand_i;
    
    wire        writeback_valid_o;
    wire [31:0] writeback_value_o;

    // ========== TEST VARIABLES ==========
    integer test_count;
    integer pass_count;
    integer fail_count;
    reg [31:0] expected_result;
    reg [200*8-1:0] test_name;

    // ========== CLOCK GENERATION ==========
    initial begin
        clk_i = 0;
        forever #5 clk_i = ~clk_i; // 100MHz clock
    end

    // ========== DUT INSTANTIATION ==========
    riscv_base_divider dut (
        .clk_i              (clk_i),
        .rst_i              (rst_i),
        .opcode_valid_i     (opcode_valid_i),
        .opcode_opcode_i    (opcode_opcode_i),
        .opcode_pc_i        (opcode_pc_i),
        .opcode_invalid_i   (opcode_invalid_i),
        .opcode_rd_idx_i    (opcode_rd_idx_i),
        .opcode_ra_idx_i    (opcode_ra_idx_i),
        .opcode_rb_idx_i    (opcode_rb_idx_i),
        .opcode_ra_operand_i(opcode_ra_operand_i),
        .opcode_rb_operand_i(opcode_rb_operand_i),
        .writeback_valid_o  (writeback_valid_o),
        .writeback_value_o  (writeback_value_o)
    );

    // ========== TASK: RESET SYSTEM ==========
    task reset_system;
        begin
            rst_i = 1;
            opcode_valid_i = 0;
            opcode_opcode_i = 0;
            opcode_pc_i = 0;
            opcode_invalid_i = 0;
            opcode_rd_idx_i = 0;
            opcode_ra_idx_i = 0;
            opcode_rb_idx_i = 0;
            opcode_ra_operand_i = 0;
            opcode_rb_operand_i = 0;
            repeat(3) @(posedge clk_i);
            rst_i = 0;
            repeat(2) @(posedge clk_i);
        end
    endtask

    // ========== TASK: EXECUTE DIVISION ==========
    task execute_division(
        input [31:0] opcode,
        input [31:0] dividend,
        input [31:0] divisor,
        input [31:0] expected,
        input [200*8-1:0] name
    );
        begin
            test_name = name;
            expected_result = expected;
            
            // Setup instruction
            opcode_valid_i = 1;
            opcode_opcode_i = opcode;
            opcode_pc_i = 32'h1000;
            opcode_invalid_i = 0;
            opcode_rd_idx_i = 5'd1;
            opcode_ra_idx_i = 5'd2;
            opcode_rb_idx_i = 5'd3;
            opcode_ra_operand_i = dividend;
            opcode_rb_operand_i = divisor;

            @(posedge clk_i);
            opcode_valid_i = 0; // Only valid for 1 cycle

            // Wait for completion
            wait(writeback_valid_o);
            @(posedge clk_i);
            
            // Check result
            check_result();
            
            // Clear valid signal
            repeat(2) @(posedge clk_i);
        end
    endtask

    // ========== TASK: CHECK RESULT ==========
    task check_result;
        begin
            test_count = test_count + 1;
            if (writeback_value_o == expected_result) begin
                $display("[PASS] Test %0d: %s", test_count, test_name);
                $display("       Dividend: %0d (0x%08h), Divisor: %0d (0x%08h)", 
                        $signed(opcode_ra_operand_i), opcode_ra_operand_i,
                        $signed(opcode_rb_operand_i), opcode_rb_operand_i);
                $display("       Expected: %0d (0x%08h), Got: %0d (0x%08h)", 
                        $signed(expected_result), expected_result,
                        $signed(writeback_value_o), writeback_value_o);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: %s", test_count, test_name);
                $display("       Dividend: %0d (0x%08h), Divisor: %0d (0x%08h)", 
                        $signed(opcode_ra_operand_i), opcode_ra_operand_i,
                        $signed(opcode_rb_operand_i), opcode_rb_operand_i);
                $display("       Expected: %0d (0x%08h), Got: %0d (0x%08h)", 
                        $signed(expected_result), expected_result,
                        $signed(writeback_value_o), writeback_value_o);
                fail_count = fail_count + 1;
            end
            $display("");
        end
    endtask

    // ========== MAIN TEST SEQUENCE ==========
    initial begin
        $display("========================================");
        $display("RISC-V Base Divider Testbench Starting");
        $display("========================================");
        
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        
        reset_system();

        // ========== BASIC DIV TESTS ==========
        $display("Testing DIV (signed division)...");
        execute_division(`INST_DIV, 32'd20, 32'd3, 32'd6, "DIV: 20 / 3 = 6");
        execute_division(`INST_DIV, 32'd100, 32'd10, 32'd10, "DIV: 100 / 10 = 10");
        execute_division(`INST_DIV, 32'd1, 32'd1, 32'd1, "DIV: 1 / 1 = 1");
        execute_division(`INST_DIV, -32'd20, 32'd3, -32'd6, "DIV: -20 / 3 = -6");
        execute_division(`INST_DIV, 32'd20, -32'd3, -32'd6, "DIV: 20 / -3 = -6");
        execute_division(`INST_DIV, -32'd20, -32'd3, 32'd6, "DIV: -20 / -3 = 6");
        
        // ========== BASIC DIVU TESTS ==========
        $display("Testing DIVU (unsigned division)...");
        execute_division(`INST_DIVU, 32'd20, 32'd3, 32'd6, "DIVU: 20 / 3 = 6");
        execute_division(`INST_DIVU, 32'hFFFFFFFF, 32'd2, 32'h7FFFFFFF, "DIVU: 0xFFFFFFFF / 2 = 0x7FFFFFFF");
        execute_division(`INST_DIVU, 32'h80000000, 32'd2, 32'h40000000, "DIVU: 0x80000000 / 2 = 0x40000000");
        
        // ========== BASIC REM TESTS ==========
        $display("Testing REM (signed remainder)...");
        execute_division(`INST_REM, 32'd20, 32'd3, 32'd2, "REM: 20 % 3 = 2");
        execute_division(`INST_REM, 32'd100, 32'd10, 32'd0, "REM: 100 % 10 = 0");
        execute_division(`INST_REM, -32'd20, 32'd3, -32'd2, "REM: -20 % 3 = -2");
        execute_division(`INST_REM, 32'd20, -32'd3, 32'd2, "REM: 20 % -3 = 2");
        execute_division(`INST_REM, -32'd20, -32'd3, -32'd2, "REM: -20 % -3 = -2");
        
        // ========== BASIC REMU TESTS ==========
        $display("Testing REMU (unsigned remainder)...");
        execute_division(`INST_REMU, 32'd20, 32'd3, 32'd2, "REMU: 20 % 3 = 2");
        execute_division(`INST_REMU, 32'hFFFFFFFF, 32'd2, 32'd1, "REMU: 0xFFFFFFFF % 2 = 1");
        execute_division(`INST_REMU, 32'h80000001, 32'd2, 32'd1, "REMU: 0x80000001 % 2 = 1");
        
        // ========== DIVIDE BY ZERO TESTS ==========
        $display("Testing divide by zero cases...");
        execute_division(`INST_DIV, 32'd10, 32'd0, 32'hFFFFFFFF, "DIV: 10 / 0 = -1");
        execute_division(`INST_DIVU, 32'd10, 32'd0, 32'hFFFFFFFF, "DIVU: 10 / 0 = -1");
        execute_division(`INST_REM, 32'd10, 32'd0, 32'd10, "REM: 10 % 0 = 10");
        execute_division(`INST_REMU, 32'd10, 32'd0, 32'd10, "REMU: 10 % 0 = 10");
        
        // ========== OVERFLOW TESTS ==========
        $display("Testing overflow cases...");
        execute_division(`INST_DIV, 32'h80000000, 32'hFFFFFFFF, 32'h80000000, "DIV: -2147483648 / -1 = -2147483648 (overflow)");
        execute_division(`INST_REM, 32'h80000000, 32'hFFFFFFFF, 32'h0, "REM: -2147483648 % -1 = 0 (overflow)");
        
        // ========== EDGE CASES ==========
        $display("Testing edge cases...");
        execute_division(`INST_DIV, 32'd0, 32'd5, 32'd0, "DIV: 0 / 5 = 0");
        execute_division(`INST_DIVU, 32'd0, 32'd5, 32'd0, "DIVU: 0 / 5 = 0");
        execute_division(`INST_REM, 32'd0, 32'd5, 32'd0, "REM: 0 % 5 = 0");
        execute_division(`INST_REMU, 32'd0, 32'd5, 32'd0, "REMU: 0 % 5 = 0");
        
        // ========== LARGE NUMBER TESTS ==========
        $display("Testing large numbers...");
        execute_division(`INST_DIVU, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'd1, "DIVU: MAX / MAX = 1");
        execute_division(`INST_REMU, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'd0, "REMU: MAX % MAX = 0");
        execute_division(`INST_DIV, 32'h7FFFFFFF, 32'd2, 32'h3FFFFFFF, "DIV: MAX_SIGNED / 2");
        
        // ========== POWER OF 2 TESTS ==========
        $display("Testing power of 2 divisions...");
        execute_division(`INST_DIVU, 32'h80000000, 32'h40000000, 32'd2, "DIVU: 2^31 / 2^30 = 2");
        execute_division(`INST_DIVU, 32'h10000000, 32'h1000, 32'h10000, "DIVU: 2^28 / 2^12 = 2^16");
        
        // ========== TEST SUMMARY ==========
        repeat(5) @(posedge clk_i);
        
        $display("========================================");
        $display("Test Summary:");
        $display("Total Tests: %0d", test_count);
        $display("Passed:      %0d", pass_count);
        $display("Failed:      %0d", fail_count);
        $display("Success Rate: %.1f%%", (pass_count * 100.0) / test_count);
        $display("========================================");
        
        if (fail_count == 0) begin
            $display("🎉 ALL TESTS PASSED! 🎉");
        end else begin
            $display("❌ %0d TEST(S) FAILED", fail_count);
        end
        
        $finish;
    end

    // ========== TIMEOUT WATCHDOG ==========
    initial begin
        #1000000; // 1ms timeout
        $display("ERROR: Testbench timeout!");
        $finish;
    end

    // ========== WAVEFORM DUMP ==========
    initial begin
        $dumpfile("riscv_base_divider_tb.vcd");
        $dumpvars(0, riscv_base_divider_tb);
    end

endmodule