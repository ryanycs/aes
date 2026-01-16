`timescale 1ps/1ps

`define CYCLE 10
`define MAX_CYCLES 1000
`define NUM_TESTS 10

module tb;

parameter WIDTH = 128;

logic             clk;
logic             rst_n;
logic             valid_i;
logic [WIDTH-1:0] a_i;
logic [WIDTH-1:0] b_i;
logic             valid_o;
logic [WIDTH-1:0] result_o;


logic [WIDTH-1:0] a [`NUM_TESTS-1:0];
logic [WIDTH-1:0] b [`NUM_TESTS-1:0];
logic [WIDTH-1:0] result [`NUM_TESTS-1:0];

initial begin
    $readmemh("tests/test_gf128_mul/a.hex", a);
    $readmemh("tests/test_gf128_mul/b.hex", b);
    $readmemh("tests/test_gf128_mul/result.hex", result);
end

int i = 0;
int recv = 0;
int error = 0;

gf128_mul dut (
    .clk,
    .rst_n,
    .valid_i,
    .a_i,
    .b_i,
    .valid_o,
    .result_o
);

always #(`CYCLE/2) clk <= ~clk;

initial begin
    clk = 1'b0;
    rst_n = 1'b0;

    #(`CYCLE*2);
    rst_n = 1'b1;
end

initial begin
    #(`MAX_CYCLES*`CYCLE);
    $display("Simulation Timeout!");
    $finish;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        a_i <= 0;
        b_i <= 0;
        valid_i <= 0;
        i <= 0;
    end else begin
        if (i < `NUM_TESTS) begin
            a_i <= a[i];
            b_i <= b[i];
            valid_i <= 1'b1;
            i <= i + 1;
        end else begin
            valid_i <= 1'b0;
            a_i <= 0;
            b_i <= 0;
        end
    end
end

always @(posedge clk) begin
    if (valid_o) begin
        if (result_o !== result[recv]) begin
            $display("Error at test %0d: expected %h, got %h", recv, result[recv], result_o);
            error <= error + 1;
        end
        recv <= recv + 1;
    end
end

initial begin
    wait (recv == `NUM_TESTS);

    if (error == 0) begin
		$display("                   //////////////////////////               ");
		$display("                   /                        /       |\__||  ");
		$display("                   /  Congratulations !!    /      / O.O  | ");
		$display("                   /                        /    /_____   | ");
		$display("                   /  Simulation PASS !!    /   /^ ^ ^ \\  |");
		$display("                   /                        /  |^ ^ ^ ^ |w| ");
		$display("                   //////////////////////////   \\m___m__|_|");
		$display();
    end else begin
		$display("                   //////////////////////////               ");
		$display("                   /                        /       |\__||  ");
		$display("                   /  OOPS !!               /      / X.X  | ");
		$display("                   /                        /    /_____   | ");
		$display("                   /  Simulation Failed !!  /   /^ ^ ^ \\  |");
		$display("                   /                        /  |^ ^ ^ ^ |w| ");
		$display("                   //////////////////////////   \\m___m__|_|");
		$display(" There are %d errors!\n", error);
		$display();
    end
    $finish;
end

`ifdef FSDB
initial begin
    $fsdbDumpfile("output/gf128_mul.fsdb");
    $fsdbDumpvars(0, tb);
    $fsdbDumpMDA();
    $fsdbDumpSVA();
end
`else
initial begin
    $dumpfile("output/gf128_mul.vcd");
    $dumpvars(0, tb);
end
`endif

endmodule
