`timescale 1ns/1ps
`include "aes.sv"
`define CYCLE 10
`define MAX_CYCLES 1000
`define NUM_TESTS 5

module tb;

logic         clk;
logic         rst_n;
logic         valid_i;
logic [127:0] plaintext_i;
logic         valid_o;
logic [127:0] ciphertext_o;

logic [127:0] round_key [10:0];
logic [127:0] plaintexts  [`NUM_TESTS:0];
logic [127:0] ciphertexts [`NUM_TESTS:0];

int i = 0;
int recv = 0;
int error = 0;

initial begin
    $readmemh("tests/test_aes/round_key.hex", round_key);
    $readmemh("tests/test_aes/input.hex", plaintexts);
    $readmemh("tests/test_aes/golden.hex", ciphertexts);
end

aes dut(
    .clk          (clk),
    .rst_n        (rst_n),
    .valid_i      (valid_i),
    .plaintext_i  (plaintext_i),
    .round_key_i  (round_key),
    .valid_o      (valid_o),
    .ciphertext_o (ciphertext_o)
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
        plaintext_i <= 128'h0;
        i <= 0;
    end else begin
        if (i < `NUM_TESTS) begin
            valid_i <= 1'b1;
            plaintext_i <= plaintexts[i];
            i <= i + 1;
        end else begin
            valid_i <= 1'b0;
            plaintext_i <= 128'h0;
        end
    end
end

// Check outputs
always @(posedge clk) begin
    if (valid_o) begin
        if (ciphertext_o !== ciphertexts[recv]) begin
            $display("Error at test %0d: expected %h, got %h", recv, ciphertexts[recv], ciphertext_o);
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
    $fsdbDumpfile("output/aes.fsdb");
    $fsdbDumpvars(0, tb);
    $fsdbDumpMDA();
    $fsdbDumpSVA();
end
`else
initial begin
    $dumpfile("output/aes.vcd");
    $dumpvars(0, tb);
end
`endif

endmodule
