`timescale 1ns/1ps
`define CYCLE 10
`define MAX_CYCLES 1000
`define NUM_TESTS 2

module tb;

logic         clk;
logic         rst_n;
logic         valid_i;
logic [127:0] key_i;
logic         valid_o;
logic [127:0] round_key [10:0];

logic [127:0] input_key [`NUM_TESTS-1 : 0];
logic [127:0] golden_round_key [`NUM_TESTS*11-1 : 0];

int i = 0;
int recv = 0;
int error = 0;

initial begin
    $readmemh("tests/test_key_expansion/input.hex", input_key);
    $readmemh("tests/test_key_expansion/golden.hex", golden_round_key);
end

key_expansion dut(
    .clk         (clk),
    .rst_n       (rst_n),
    .valid_i     (valid_i),
    .key_i       (key_i),
    .valid_o     (valid_o),
    .round_key_o (round_key)
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
        key_i <= 128'h0;
        i <= 0;
    end else begin
        if (i == 0 || valid_o) begin
            valid_i <= 1'b1;
            key_i <= input_key[i];
            i <= i + 1;
        end else begin
            valid_i <= 1'b0;
            key_i <= 128'h0;
        end
    end
end

// Check outputs
always @(posedge clk) begin
    if (valid_o) begin
        $display("Checking test case %0d", recv);
        for (int j = 0; j < 11; j = j + 1) begin
            if (round_key[j] !== golden_round_key[recv * 11 + j]) begin
                $display("Mismatch at round key %0d: expected %h, got %h", j, golden_round_key[recv * 11 + j], round_key[j]);
                error = error + 1;
            end
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
    $fsdbDumpfile("output/key_expansion.fsdb");
    $fsdbDumpvars(0, tb);
    $fsdbDumpMDA();
    $fsdbDumpSVA();
end
`else
initial begin
    $dumpfile("output/key_expansion.vcd");
    $dumpvars(0, tb);
end
`endif

endmodule
