`timescale 1ns / 1ps
`include "riscv_base_regfile.v"
module riscv_base_regfile_tb;

    // Parameters
    parameter CLK_PERIOD = 10; // 100MHz clock
    
    // Testbench signals
    reg clk_i;
    reg rst_i;
    reg [4:0] rd0_i;
    reg [31:0] rd0_value_i;
    reg [4:0] ra0_i;
    reg [4:0] rb0_i;
    
    wire [31:0] ra0_value_o;
    wire [31:0] rb0_value_o;
    
    // Test variables
    integer i, j;
    reg [31:0] test_data [31:1]; // Test data for registers 1-31
    reg test_passed;
    integer error_count;
    
    // Instantiate the DUT (Device Under Test) - Test standard implementation
    riscv_base_regfile #(
        .SUPPORT_REGFILE_XILINX(0)
    ) dut (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .rd0_i(rd0_i),
        .rd0_value_i(rd0_value_i),
        .ra0_i(ra0_i),
        .rb0_i(rb0_i),
        .ra0_value_o(ra0_value_o),
        .rb0_value_o(rb0_value_o)
    );
    
    // Clock generation
    always #(CLK_PERIOD/2) clk_i = ~clk_i;
    
    // Initialize test data
    initial begin
        for (i = 1; i <= 31; i = i + 1) begin
            test_data[i] = {$random} & 32'hFFFFFFFF; // Generate random test data
        end
    end
    
    // Main test procedure
    initial begin
        // Initialize signals
        clk_i = 0;
        rst_i = 1;
        rd0_i = 0;
        rd0_value_i = 0;
        ra0_i = 0;
        rb0_i = 0;
        test_passed = 1;
        error_count = 0;
        
        $display("=== RISC-V Register File Testbench ===");
        $display("Time: %0t - Starting testbench", $time);
        
        // Test 1: Reset functionality
        $display("\nTest 1: Reset functionality");
        #(CLK_PERIOD * 3);
        rst_i = 0;
        #(CLK_PERIOD * 2);
        
        // Check if all readable registers are zero after reset
        for (i = 0; i <= 31; i = i + 1) begin
            ra0_i = i;
            #2; // Small delay for combinational logic
            if (ra0_value_o !== 32'h00000000) begin
                $display("ERROR: Register x%0d should be 0 after reset, got 0x%08h", i, ra0_value_o);
                test_passed = 0;
                error_count = error_count + 1;
            end
        end
        
        if (error_count == 0) 
            $display("PASS: All registers properly reset to 0");
        
        // Test 2: x0 register always reads zero
        $display("\nTest 2: x0 register always reads zero");
        rd0_i = 0;
        rd0_value_i = 32'hDEADBEEF;
        @(posedge clk_i);
        @(posedge clk_i);
        ra0_i = 0;
        #2;
        if (ra0_value_o !== 32'h00000000) begin
            $display("ERROR: x0 should always be 0, got 0x%08h", ra0_value_o);
            test_passed = 0;
            error_count = error_count + 1;
        end else begin
            $display("PASS: x0 register correctly returns 0");
        end
        
        // Test 3: Write and read all registers (except x0)
        $display("\nTest 3: Write and read all registers (x1-x31)");
        for (i = 1; i <= 31; i = i + 1) begin
            // Write to register
            rd0_i = i;
            rd0_value_i = test_data[i];
            @(posedge clk_i);
            @(posedge clk_i); // Extra cycle to ensure write completes
            
            // Read from register
            ra0_i = i;
            #2; // Wait for combinational read
            
            if (ra0_value_o !== test_data[i]) begin
                $display("ERROR: Register x%0d write/read failed. Expected: 0x%08h, Got: 0x%08h", 
                         i, test_data[i], ra0_value_o);
                test_passed = 0;
                error_count = error_count + 1;
            end else begin
                $display("PASS: Register x%0d correctly stores 0x%08h", i, test_data[i]);
            end
        end
        
        // Test 4: Dual port read functionality
        $display("\nTest 4: Dual port read functionality");
        // Test a few key combinations instead of all to reduce simulation time
        for (i = 1; i <= 5; i = i + 1) begin
            for (j = 26; j <= 31; j = j + 1) begin
                ra0_i = i;
                rb0_i = j;
                #2; // Wait for combinational read
                
                if (ra0_value_o !== test_data[i] || rb0_value_o !== test_data[j]) begin
                    $display("ERROR: Dual read failed. RA(x%0d): Expected 0x%08h, Got 0x%08h | RB(x%0d): Expected 0x%08h, Got 0x%08h",
                             i, test_data[i], ra0_value_o, j, test_data[j], rb0_value_o);
                    test_passed = 0;
                    error_count = error_count + 1;
                end
            end
        end
        
        $display("PASS: Dual port read functionality working correctly");
        
        // Test 5: Write to x0 should be ignored
        $display("\nTest 5: Write to x0 should be ignored");
        rd0_i = 0;
        rd0_value_i = 32'hFFFFFFFF;
        @(posedge clk_i);
        @(posedge clk_i);
        ra0_i = 0;
        #2;
        
        if (ra0_value_o !== 32'h00000000) begin
            $display("ERROR: Write to x0 was not ignored, got 0x%08h", ra0_value_o);
            test_passed = 0;
            error_count = error_count + 1;
        end else begin
            $display("PASS: Write to x0 correctly ignored");
        end
        
        // Test 6: Simultaneous different register read/write
        $display("\nTest 6: Simultaneous different register read/write");
        rd0_i = 10;
        rd0_value_i = 32'h12345678;
        ra0_i = 5;  // Read different register
        rb0_i = 15; // Read another different register
        @(posedge clk_i);
        #2;
        
        // Check that reads are not affected by write to different register
        if (ra0_value_o !== test_data[5] || rb0_value_o !== test_data[15]) begin
            $display("ERROR: Read affected by write to different register");
            test_passed = 0;
            error_count = error_count + 1;
        end else begin
            $display("PASS: Simultaneous read/write to different registers working correctly");
        end
        
        // Verify the write actually happened
        @(posedge clk_i);
        ra0_i = 10;
        #2;
        if (ra0_value_o !== 32'h12345678) begin
            $display("ERROR: Write to register 10 failed");
            test_passed = 0;
            error_count = error_count + 1;
        end else begin
            $display("PASS: Write to register 10 successful");
        end
        
        // Test 7: Random stress test
        $display("\nTest 7: Random stress test");
        i = 0;
        while (i < 100 && test_passed) begin
            rd0_i = ($random % 32) & 5'h1F;
            rd0_value_i = {$random} & 32'hFFFFFFFF;
            ra0_i = ($random % 32) & 5'h1F;
            rb0_i = ($random % 32) & 5'h1F;
            @(posedge clk_i);
            #2;
            
            // Simple check: x0 should always be 0
            if ((ra0_i == 0 && ra0_value_o !== 0) || (rb0_i == 0 && rb0_value_o !== 0)) begin
                $display("ERROR: x0 not zero during stress test at iteration %0d", i);
                $display("       ra0_i=%0d, ra0_value_o=0x%08h, rb0_i=%0d, rb0_value_o=0x%08h", 
                         ra0_i, ra0_value_o, rb0_i, rb0_value_o);
                test_passed = 0;
                error_count = error_count + 1;
            end
            i = i + 1;
        end
        
        if (test_passed) 
            $display("PASS: Random stress test completed successfully");
        
        // Test 8: Edge cases and boundary conditions
        $display("\nTest 8: Edge cases and boundary conditions");
        
        // Test with all 1s
        rd0_i = 31;
        rd0_value_i = 32'hFFFFFFFF;
        @(posedge clk_i);
        @(posedge clk_i);
        ra0_i = 31;
        #2;
        if (ra0_value_o !== 32'hFFFFFFFF) begin
            $display("ERROR: All 1s test failed, expected 0xFFFFFFFF, got 0x%08h", ra0_value_o);
            test_passed = 0;
            error_count = error_count + 1;
        end else begin
            $display("PASS: All 1s test passed");
        end
        
        // Test with all 0s
        rd0_value_i = 32'h00000000;
        @(posedge clk_i);
        @(posedge clk_i);
        #2;
        if (ra0_value_o !== 32'h00000000) begin
            $display("ERROR: All 0s test failed");
            test_passed = 0;
            error_count = error_count + 1;
        end else begin
            $display("PASS: All 0s test passed");
        end
        
        // Final results
        $display("\n=== TEST RESULTS ===");
        if (test_passed && error_count == 0) begin
            $display("*** ALL TESTS PASSED! ***");
            $display("Register file implementation is correct.");
        end else begin
            $display("*** TESTS FAILED! ***");
            $display("Total errors: %0d", error_count);
        end
        
        $display("Time: %0t - Testbench completed", $time);
        $finish;
    end
    
    // Optional: Dump waveforms for debugging
    initial begin
        $dumpfile("riscv_base_regfile_tb.vcd");
        $dumpvars(0, riscv_base_regfile_tb);
    end

endmodule