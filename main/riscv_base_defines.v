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
//1. mul
// mul
`define INST_MUL 32'h2000033
`define INST_MUL_MASK 32'hfe00707f

//2. mulh
`define INST_MULH 32'h2001033
`define INST_MULH_MASK 32'hfe00707f

//3. mulhsu
`define INST_MULHSU 32'h2002033
`define INST_MULHSU_MASK 32'hfe00707f

//4. mulhu
`define INST_MULHU 32'h2003033
`define INST_MULHU_MASK 32'hfe00707f