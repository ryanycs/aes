`timescale 1ns/1ps

`include "define.svh"

`define CYCLE 10
`define MAX_CYCLES 1000
`define NUM_TESTS 1

module tb;

logic         clk;
logic         rst_n;
logic         en;
logic         valid_i;
logic [127:0] plaintext_i;
logic         valid_o;
logic [127:0] ciphertext_o;

logic [127:0] round_key [Nr:0];
logic [127:0] plaintext [0:0];
logic [127:0] ciphertext [0:0];

int i = 0;
int recv = 0;
int error = 0;

`ifdef AES192
initial begin
    $readmemh("tests/test_aes/aes192/round_key.hex", round_key);
    $readmemh("tests/test_aes/aes192/plaintext.hex", plaintext);
    $readmemh("tests/test_aes/aes192/ciphertext.hex", ciphertext);
end
`elsif AES256
initial begin
    $readmemh("tests/test_aes/aes256/round_key.hex", round_key);
    $readmemh("tests/test_aes/aes256/plaintext.hex", plaintext);
    $readmemh("tests/test_aes/aes256/ciphertext.hex", ciphertext);
end
`else
initial begin
    $readmemh("tests/test_aes/aes128/round_key.hex", round_key);
    $readmemh("tests/test_aes/aes128/plaintext.hex", plaintext);
    $readmemh("tests/test_aes/aes128/ciphertext.hex", ciphertext);
end
`endif

aes dut(
    .clk          (clk),
    .rst_n        (rst_n),
    .en           (en),
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
        en <= 1'b0;
        plaintext_i <= 128'h0;
        i <= 0;
    end else begin
        if (i < `NUM_TESTS) begin
            // Randomly enable or disable 'en' signal
            if ($urandom_range(0,1) == 1) begin
                en <= 1'b1;
                valid_i <= 1'b1;
                plaintext_i <= plaintext[i];
                i <= i + 1;
            end else begin
                en <= 1'b0;
                valid_i <= 1'b0;
                plaintext_i <= 128'h0;
            end
        end else begin
            valid_i <= 1'b0;
            plaintext_i <= 128'h0;
        end
    end
end

// Check outputs
always @(posedge clk) begin
    if (valid_o) begin
        if (ciphertext_o !== ciphertext[recv]) begin
            $display("Error at test %0d: expected %h, got %h", recv, ciphertext[recv], ciphertext_o);
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
