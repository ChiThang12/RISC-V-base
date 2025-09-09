// Định nghĩa macro trong ALU
`define ALU_NONE                        4'b0000
`define ALU_SHIFT_LEFT                  4'b0001
`define ALU_SHIFT_RIGHT                 4'b0010
`define ALU_SHIFT_RIGHT_ARITHMETIC      4'b0011
`define ALU_ADD                         4'b0100
`define ALU_SUB                         4'b0101
`define ALU_AND                         4'b0110
`define ALU_OR                          4'b0111
`define ALU_XOR                         4'b1000
`define ALU_LESS_THAN                   4'b1001
`define ALU_LESS_THAN_UNSIGNED          4'b1010

// Định nghĩa macro trong bộ NHÂN
// 1. MUL - Nhân có dấu 32-bit, trả về 32 bit thấp
`define INST_MUL        32'h02000033
`define INST_MUL_MASK   32'hfe00707f

// 2. MULH - Nhân có dấu, trả về 32 bit cao
`define INST_MULH       32'h02002033
`define INST_MULH_MASK  32'hfe00707f

// 3. MULHSU - Nhân có dấu với không dấu, trả về 32 bit cao
`define INST_MULHSU     32'h02003033
`define INST_MULHSU_MASK 32'hfe00707f

// 4. MULHU - Nhân không dấu, trả về 32 bit cao
`define INST_MULHU      32'h02001033
`define INST_MULHU_MASK 32'hfe00707f

// Định nghĩa macro trong bộ CHIA
//1. div
`define INST_DIV 32'h2004033
`define INST_DIV_MASK 32'hfe00707f

//2. divu
`define INST_DIVU 32'h2005033
`define INST_DIVU_MASK 32'hfe00707f

//3. rem
`define INST_REM 32'h2006033
`define INST_REM_MASK 32'hfe00707f

//4. remu
`define INST_REMU 32'h2007033
`define INST_REMU_MASK 32'hfe00707f
