`timescale 1ns/1ps
`include "mix_columns.sv"
`define CYCLE 10
`define MAX_CYCLES 1000
`define NUM_TESTS 9

module tb;

logic         clk;
logic         rst_n;
logic         valid_i;
logic [127:0] state_i;
logic         valid_o;
logic [127:0] state_o;

logic [127:0] input_state  [`NUM_TESTS:0];
logic [127:0] golden_state [`NUM_TESTS:0];

int i = 0;
int recv = 0;
int error = 0;

initial begin
    $readmemh("tests/test_mix_columns/input.hex", input_state);
    $readmemh("tests/test_mix_columns/golden.hex", golden_state);
end

mix_columns dut(
    .clk     (clk),
    .rst_n   (rst_n),
    .valid_i (valid_i),
    .state_i (state_i),
    .valid_o (valid_o),
    .state_o (state_o)
);

always #(`CYCLE/2) clk = ~clk;

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

// Feed inputs
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_i <= 1'b0;
        state_i <= 128'h0;
        i <= 0;
    end else begin
        if (i < `NUM_TESTS) begin
            valid_i <= 1'b1;
            state_i <= input_state[i];
            i <= i + 1;
        end else begin
            valid_i <= 1'b0;
            state_i <= 128'h0;
        end
    end
end

// Check outputs
always @(posedge clk) begin
    if (valid_o) begin
        if (state_o !== golden_state[recv]) begin
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
    $fsdbDumpfile("output/mix_columns.fsdb");
    $fsdbDumpvars(0, tb);
    $fsdbDumpMDA();
    $fsdbDumpSVA();
end
`else
initial begin
    $dumpfile("output/mix_columns.vcd");
    $dumpvars(0, tb);
end
`endif

endmodule
