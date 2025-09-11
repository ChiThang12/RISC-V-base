`timescale 1ns / 1ps
`include "riscv_base_trace_sim.v"
`include "riscv_base_defines.v"
module tb_riscv_base_trace_sim;

    // Testbench signals
    reg valid;
    reg [31:0] pc;
    reg [31:0] opcode;
    
    // Test case storage arrays
    reg [31:0] test_pc [0:24];
    reg [31:0] test_opcode [0:24];
    reg [31:0] test_imm [0:24];
    
    // Expected results as packed strings (80 bits each)
    reg [79:0] test_inst [0:24];
    reg [79:0] test_rd [0:24];
    reg [79:0] test_ra [0:24];  
    reg [79:0] test_rb [0:24];
    
    integer i;
    integer pass_count, fail_count;
    
    // Instantiate the module under test
    riscv_base_trace_sim uut (
        .valid_i(valid),
        .pc_i(pc),
        .opcode_i(opcode)
    );
    
    initial begin
        $display("========================================");
        $display("RISC-V Base Trace Simulation Testbench");
        $display("========================================");
        
        // Initialize signals
        valid = 0;
        pc = 0;
        opcode = 0;
        pass_count = 0;
        fail_count = 0;
        
        // Wait for a few cycles
        #10;
        
        // Initialize test cases
        init_test_cases();
        
        // Run test cases
        for (i = 0; i < 25; i = i + 1) begin
            run_test_case(i);
            #10; // Small delay between tests
        end
        
        // Test invalid case (valid = 0)
        $display("\n--- Testing invalid case ---");
        valid = 0;
        pc = 32'h12345678;
        opcode = 32'h87654321;
        #1;
        
        if (uut.dbg_inst_pc === 32'bx && uut.dbg_inst_str == "-") begin
            $display("PASS: Invalid case handled correctly");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Invalid case not handled correctly");
            fail_count = fail_count + 1;
        end
        
        $display("\n========================================");
        $display("Test Summary:");
        $display("PASSED: %0d", pass_count);
        $display("FAILED: %0d", fail_count);
        $display("TOTAL:  %0d", pass_count + fail_count);
        $display("========================================");
        $finish;
    end
    
    // Task to initialize all test cases
    task init_test_cases;
        begin
            // Test 0: ADDI x1, x0, 100 (0x06400093)
            test_pc[0] = 32'h00000000;
            test_opcode[0] = 32'h06400093;
            test_inst[0] = "addi";
            test_rd[0] = "ra";
            test_ra[0] = "zero";
            test_rb[0] = "-";
            test_imm[0] = 32'd100;
            
            // Test 1: ADD x2, x1, x0 (0x001080b3)  
            test_pc[1] = 32'h00000004;
            test_opcode[1] = 32'h001080b3;
            test_inst[1] = "add";
            test_rd[1] = "sp";
            test_ra[1] = "ra";
            test_rb[1] = "zero";
            test_imm[1] = 32'h0;
            
            // Test 2: LUI x3, 0x12345 (0x12345137)
            test_pc[2] = 32'h00000008;
            test_opcode[2] = 32'h12345137;
            test_inst[2] = "lui";
            test_rd[2] = "gp";
            test_ra[2] = "-";
            test_rb[2] = "-";
            test_imm[2] = 32'h12345000;
            
            // Test 3: BEQ x1, x2, 8 (0x00208463)
            test_pc[3] = 32'h0000000C;
            test_opcode[3] = 32'h00208463;
            test_inst[3] = "beq";
            test_rd[3] = "-";
            test_ra[3] = "ra";
            test_rb[3] = "sp";
            test_imm[3] = 32'h00000014; // PC + 8
            
            // Test 4: JAL x1, 16 - Use correct calculated opcode
            test_pc[4] = 32'h00000010;
            test_opcode[4] = 32'h010000ef; // Correct opcode for JAL x1,16
            test_inst[4] = "call"; // Should be "call" since rd=x1
            test_rd[4] = "ra";     // x1 = ra
            test_ra[4] = "-";
            test_rb[4] = "-";
            test_imm[4] = 32'h00000020; // PC(0x10) + 16 = 0x20
            
            // Test 5: JALR x0, x1, 0 (0x00008067)
            test_pc[5] = 32'h00000014;
            test_opcode[5] = 32'h00008067;
            test_inst[5] = "ret"; // Should be "ret" since rs1=x1 and imm=0
            test_rd[5] = "zero";
            test_ra[5] = "ra";
            test_rb[5] = "-";
            test_imm[5] = 32'h0;
            
            // Test 6: LW x5, 4(x2) (0x00412283)
            test_pc[6] = 32'h00000018;
            test_opcode[6] = 32'h00412283;
            test_inst[6] = "lw";
            test_rd[6] = "t0";
            test_ra[6] = "sp";
            test_rb[6] = "-";
            test_imm[6] = 32'd4;
            
            // Test 7: SW x5, 8(x2) (0x00512423)
            test_pc[7] = 32'h0000001C;
            test_opcode[7] = 32'h00512423;
            test_inst[7] = "sw";
            test_rd[7] = "-";
            test_ra[7] = "sp";
            test_rb[7] = "t0";
            test_imm[7] = 32'd8;
            
            // Test 8: SLLI x6, x5, 2 (0x00229313)
            test_pc[8] = 32'h00000020;
            test_opcode[8] = 32'h00229313;
            test_inst[8] = "slli";
            test_rd[8] = "t1";
            test_ra[8] = "t0";
            test_rb[8] = "-";
            test_imm[8] = 32'd2;
            
            // Test 9: XOR x7, x5, x6 (0x0062c3b3)
            test_pc[9] = 32'h00000024;
            test_opcode[9] = 32'h0062c3b3;
            test_inst[9] = "xor";
            test_rd[9] = "t2";
            test_ra[9] = "t0";
            test_rb[9] = "t1";
            test_imm[9] = 32'h0;
            
            // Test 10: AUIPC x8, 0x1000 (0x01000417)
            test_pc[10] = 32'h00000028;
            test_opcode[10] = 32'h01000417;
            test_inst[10] = "auipc";
            test_rd[10] = "s0";
            test_ra[10] = "pc";
            test_rb[10] = "-";
            test_imm[10] = 32'h01000000;
            
            // Test 11: SLTI x9, x8, -100 (0xf9c42493)
            test_pc[11] = 32'h0000002C;
            test_opcode[11] = 32'hf9c42493;
            test_inst[11] = "slti";
            test_rd[11] = "s1";
            test_ra[11] = "s0";
            test_rb[11] = "-";
            test_imm[11] = 32'hffffff9c; // -100 sign extended
            
            // Test 12: MUL x10, x8, x9 (0x02940533)
            test_pc[12] = 32'h00000030;
            test_opcode[12] = 32'h02940533;
            test_inst[12] = "mul";
            test_rd[12] = "a0";
            test_ra[12] = "s0";
            test_rb[12] = "s1";
            test_imm[12] = 32'h0;
            
            // Test 13: DIV x11, x10, x9 (0x029545b3)
            test_pc[13] = 32'h00000034;
            test_opcode[13] = 32'h029545b3;
            test_inst[13] = "div";
            test_rd[13] = "a1";
            test_ra[13] = "a0";
            test_rb[13] = "s1";
            test_imm[13] = 32'h0;
            
            // Test 14: ECALL (0x00000073)
            test_pc[14] = 32'h00000038;
            test_opcode[14] = 32'h00000073;
            test_inst[14] = "ecall";
            test_rd[14] = "-";
            test_ra[14] = "-";
            test_rb[14] = "-";
            test_imm[14] = 32'h0;
            
            // Test 15: EBREAK (0x00100073)
            test_pc[15] = 32'h0000003C;
            test_opcode[15] = 32'h00100073;
            test_inst[15] = "ebreak";
            test_rd[15] = "-";
            test_ra[15] = "-";
            test_rb[15] = "-";
            test_imm[15] = 32'h0;
            
            // Test 16: BLT x5, x6, -4 (0xfe62cee3)
            test_pc[16] = 32'h00000040;
            test_opcode[16] = 32'hfe62cee3;
            test_inst[16] = "blt";
            test_rd[16] = "-";
            test_ra[16] = "t0";
            test_rb[16] = "t1";
            test_imm[16] = 32'h0000003c; // PC - 4
            
            // Test 17: CSRRW x12, 0x300, x11 (0x30059673)
            test_pc[17] = 32'h00000044;
            test_opcode[17] = 32'h30059673;
            test_inst[17] = "csrrw";
            test_rd[17] = "a2";
            test_ra[17] = "a1";
            test_rb[17] = "-";
            test_imm[17] = 32'h300;
            
            // Test 18: LB x13, -1(x12) (0xfff60683)
            test_pc[18] = 32'h00000048;
            test_opcode[18] = 32'hfff60683;
            test_inst[18] = "lb";
            test_rd[18] = "a3";
            test_ra[18] = "a2";
            test_rb[18] = "-";
            test_imm[18] = 32'hffffffff; // -1 sign extended
            
            // Test 19: SH x13, 2(x12) (0x00d61123)
            test_pc[19] = 32'h0000004C;
            test_opcode[19] = 32'h00d61123;
            test_inst[19] = "sh";
            test_rd[19] = "-";
            test_ra[19] = "a2";
            test_rb[19] = "a3";
            test_imm[19] = 32'd2;
            
            // Test 20: ORI x14, x13, 0xFF (0x0ff6e713)
            test_pc[20] = 32'h00000050;
            test_opcode[20] = 32'h0ff6e713;
            test_inst[20] = "ori";
            test_rd[20] = "a4";
            test_ra[20] = "a3";
            test_rb[20] = "-";
            test_imm[20] = 32'h000000FF;
            
            // Test 21: ANDI x15, x14, 0x0F0 (0x0f077793)
            test_pc[21] = 32'h00000054;
            test_opcode[21] = 32'h0f077793;
            test_inst[21] = "andi";
            test_rd[21] = "a5";
            test_ra[21] = "a4";
            test_rb[21] = "-";
            test_imm[21] = 32'h000000F0;
            
            // Test 22: SRA x16, x15, x14 (0x40e7d833)
            test_pc[22] = 32'h00000058;
            test_opcode[22] = 32'h40e7d833;
            test_inst[22] = "sra";
            test_rd[22] = "a6";
            test_ra[22] = "a5";
            test_rb[22] = "a4";
            test_imm[22] = 32'h0;
            
            // Test 23: BGE x15, x14, 12 (0x00e7d663)
            test_pc[23] = 32'h0000005C;
            test_opcode[23] = 32'h00e7d663;
            test_inst[23] = "bge";
            test_rd[23] = "-";
            test_ra[23] = "a5";
            test_rb[23] = "a4";
            test_imm[23] = 32'h00000068; // PC + 12
            
            // Test 24: Unknown instruction
            test_pc[24] = 32'h00000060;
            test_opcode[24] = 32'hFFFFFFFF;
            test_inst[24] = "unknown";
            test_rd[24] = "-";
            test_ra[24] = "-";
            test_rb[24] = "-";
            test_imm[24] = 32'h0;
        end
    endtask
    
    // Task to run individual test case
    task run_test_case;
        input integer test_num;
        reg test_passed;
        begin
            $display("\n--- Test %0d ---", test_num);
            test_passed = 1;
            
            // Set inputs
            valid = 1;
            pc = test_pc[test_num];
            opcode = test_opcode[test_num];
            
            // Wait for combinational logic to settle
            #1;
            
            // Display test info
            $display("PC: 0x%08h, Opcode: 0x%08h", test_pc[test_num], test_opcode[test_num]);
            $display("Expected: %s %s, %s, %s (imm=0x%08h)", 
                     test_inst[test_num], test_rd[test_num], test_ra[test_num], test_rb[test_num], test_imm[test_num]);
            $display("Actual:   %s %s, %s, %s (imm=0x%08h)", 
                     uut.dbg_inst_str, uut.dbg_inst_rd, uut.dbg_inst_ra, uut.dbg_inst_rb, uut.dbg_inst_imm);
            
            // Check results
            if (uut.dbg_inst_str != test_inst[test_num]) begin
                $display("FAIL: Instruction mismatch");
                test_passed = 0;
            end
            
            if (uut.dbg_inst_rd != test_rd[test_num]) begin
                $display("FAIL: RD mismatch");
                test_passed = 0;
            end
            
            if (uut.dbg_inst_ra != test_ra[test_num]) begin
                $display("FAIL: RA mismatch");
                test_passed = 0;
            end
            
            if (uut.dbg_inst_rb != test_rb[test_num]) begin
                $display("FAIL: RB mismatch");
                test_passed = 0;
            end
            
            if (uut.dbg_inst_imm !== test_imm[test_num]) begin
                $display("FAIL: IMM mismatch - Expected: 0x%08h, Got: 0x%08h", 
                         test_imm[test_num], uut.dbg_inst_imm);
                test_passed = 0;
            end
            
            if (uut.dbg_inst_pc !== test_pc[test_num]) begin
                $display("FAIL: PC mismatch - Expected: 0x%08h, Got: 0x%08h", 
                         test_pc[test_num], uut.dbg_inst_pc);
                test_passed = 0;
            end
            
            if (test_passed) begin
                $display("PASS: Test %0d passed", test_num);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Test %0d failed", test_num);
                fail_count = fail_count + 1;
            end
        end
    endtask

endmodule