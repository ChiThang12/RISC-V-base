module divider_8bit (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [7:0]  dividend,
    input  wire [7:0]  divisor,

    output reg  [7:0]  quotient,
    output reg  [7:0]  remainder,
    output reg         busy,
    output reg         done
);

    // Registers
    reg [7:0] quotient_q;      // Q
    reg [7:0] divisor_q;       // D
    reg [8:0] remainder_q;     // R (1 bit rộng hơn để kiểm tra âm)
    reg [3:0] count;           // đếm 8 bước

    // Wires cho giá trị tiếp theo
    reg [7:0] quotient_next;
    reg [8:0] remainder_next;

    // -------------------------------------------------------------------
    // Combinational logic: tính toán R_next, Q_next
    // -------------------------------------------------------------------
    always @(*) begin
        quotient_next  = quotient_q;
        remainder_next = remainder_q;

        if (busy) begin
            // Step 1: shift (R,Q)
            remainder_next = {remainder_q[7:0], quotient_q[7]};
            quotient_next  = {quotient_q[6:0], 1'b0};

            // Step 2: subtract divisor
            remainder_next = remainder_next - {1'b0, divisor_q};

            // Step 3: check sign
            if (remainder_next[8]) begin
                // Nếu âm → restore
                remainder_next = remainder_next + {1'b0, divisor_q};
                quotient_next[0] = 1'b0;
            end else begin
                quotient_next[0] = 1'b1;
            end
        end
    end

    // -------------------------------------------------------------------
    // Sequential logic: cập nhật
    // -------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            quotient_q  <= 0;
            divisor_q   <= 0;
            remainder_q <= 0;
            quotient    <= 0;
            remainder   <= 0;
            count       <= 0;
            busy        <= 0;
            done        <= 0;
        end else if (start && !busy) begin
            if (divisor == 0) begin
                // Trường hợp chia cho 0
                quotient <= 8'hFF;   // hoặc báo lỗi
                remainder <= dividend;
                busy <= 0;
                done <= 1;
            end else begin
                // Khởi tạo
                quotient_q  <= dividend;
                divisor_q   <= divisor;
                remainder_q <= 0;
                count       <= 8;
                busy        <= 1;
                done        <= 0;
            end
        end else if (busy) begin
            quotient_q  <= quotient_next;
            remainder_q <= remainder_next;
            count       <= count - 1;

            if (count == 1) begin
                busy      <= 0;
                done      <= 1;
                quotient  <= quotient_next;
                remainder <= remainder_next[7:0];
            end
        end else begin
            done <= 0; // clear sau khi đọc xong
        end
    end

endmodule


`timescale 1ns/1ps

module divider_8bit_tb();

    // Định nghĩa các tín hiệu test
    reg         clk;
    reg         rst;
    reg         start;
    reg  [7:0]  dividend;
    reg  [7:0]  divisor;
    wire [7:0]  quotient;
    wire [7:0]  remainder;
    wire        busy;
    wire        done;

    // Khởi tạo DUT (Device Under Test)
    divider_8bit dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .dividend(dividend),
        .divisor(divisor),
        .quotient(quotient),
        .remainder(remainder),
        .busy(busy),
        .done(done)
    );

    // Tạo xung clock 100MHz (chu kỳ 10ns)
    always #5 clk = ~clk;

    // Task kiểm tra kết quả
    task check_division;
        input [7:0] div_in;    // Số bị chia
        input [7:0] div_by;    // Số chia
        input [7:0] exp_q;     // Thương số mong đợi
        input [7:0] exp_r;     // Số dư mong đợi
        begin
            @(posedge clk);
            start = 1;
            dividend = div_in;
            divisor = div_by;
            @(posedge clk);
            start = 0;
            
            // Đợi cho đến khi done=1
            wait(done);
            
            // Kiểm tra kết quả
            if (quotient !== exp_q || remainder !== exp_r) begin
                $display("Lỗi: %d/%d = %d dư %d (mong đợi %d dư %d)", 
                    div_in, div_by, quotient, remainder, exp_q, exp_r);
            end else begin
                $display("Đúng: %d/%d = %d dư %d", 
                    div_in, div_by, quotient, remainder);
            end
            
            @(posedge clk);
            wait(!done);  // Đợi done về 0
        end
    endtask

    // Test stimulus
    initial begin
        // Tạo file wave
        $dumpfile("divider_tb.vcd");
        $dumpvars(0, divider_8bit_tb);

        // Khởi tạo các tín hiệu
        clk = 0;
        rst = 1;
        start = 0;
        dividend = 0;
        divisor = 0;

        // Reset
        #100;
        rst = 0;
        #10;

        // Test case 1: 25/4 = 6 dư 1
        check_division(8'd25, 8'd4, 8'd6, 8'd1);

        // Test case 2: 255/2 = 127 dư 1
        check_division(8'd255, 8'd2, 8'd127, 8'd1);

        // Test case 3: 100/10 = 10 dư 0
        check_division(8'd100, 8'd10, 8'd10, 8'd0);

        // Test case 4: 7/9 = 0 dư 7
        check_division(8'd7, 8'd9, 8'd0, 8'd7);

        // Test case 5: Chia cho 0
        check_division(8'd123, 8'd0, 8'hFF, 8'd123);

        // Kết thúc test
        #100;
        $display("Hoàn thành tất cả test!");
        $finish;
    end

    // Monitor các thay đổi
    initial begin
        $monitor("Time=%0d rst=%b start=%b busy=%b done=%b dividend=%d divisor=%d q=%d r=%d",
            $time, rst, start, busy, done, dividend, divisor, quotient, remainder);
    end

endmodule