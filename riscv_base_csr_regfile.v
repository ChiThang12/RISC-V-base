module riscv_base_csr_regfile#(
    parameter SUPPORT_MTIMECMO = 1;
    parameter SUPPORT_SUPER = 0;
)(  
    input clk_in,
    input rst_in,

    input ext_intr_in,
    input timer_intr_in,

    input [31:0] cpu_id_i,
    input [31:0] misa_i,

    input [5:0] exception_i,
    input [31:0] exception_pc_i,
    input [31:0] exception_addr_i,

    // CSR read port
    input csr_ren_i,
    input [11:0] csr_raddr_i,

    output [31:0] csr_rdata_o,


    // CSR write port
    input [11:0] csr_waddr_i,
    input [31:0] csr_wdata_i,

    output csr_branch_o,
    output [31:0] csr_target_o,

    // csr reg
    output [1:0] priv_o,
    output [31:0] status_o,
    output [31:0] satp_o,

    output [31:0] interrupt_o,

);

endmodule