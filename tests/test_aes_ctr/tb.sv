`timescale 1ns/10ps

`include "define.svh"

`define CYCLE 10
`define MAX_CYCLES 1000
`define NUM_TESTS 4

module tb;

// AES CTR port
logic                clk;
logic                rst_n;
logic [KEY_SIZE-1:0] key_i;
logic                key_valid_i;
logic                key_ready_o;
logic [127:0]        iv_i;
logic                iv_valid_i;
logic [127:0]        din_i;
logic                din_valid_i;
logic                din_ready_o;
logic [127:0]        dout_o;
logic                dout_valid_o;
logic                dout_ready_i;

logic [KEY_SIZE-1:0] key        [0:0];
logic [127:0]        iv         [0:0];
logic [127:0]        plaintext  [`NUM_TESTS-1:0];
logic [127:0]        ciphertext [`NUM_TESTS-1:0];

int i = 0;
int recv = 0;
int error = 0;

`ifdef AES192
initial begin
    $readmemh("tests/test_aes_ctr/aes192/key.hex", key);
    $readmemh("tests/test_aes_ctr/aes192/iv.hex", iv);
    $readmemh("tests/test_aes_ctr/aes192/plaintext.hex", plaintext);
    $readmemh("tests/test_aes_ctr/aes192/ciphertext.hex", ciphertext);
end
`elsif AES256
initial begin
    $readmemh("tests/test_aes_ctr/aes256/key.hex", key);
    $readmemh("tests/test_aes_ctr/aes256/iv.hex", iv);
    $readmemh("tests/test_aes_ctr/aes256/plaintext.hex", plaintext);
    $readmemh("tests/test_aes_ctr/aes256/ciphertext.hex", ciphertext);
end
`else
initial begin
    $readmemh("tests/test_aes_ctr/aes128/key.hex", key);
    $readmemh("tests/test_aes_ctr/aes128/iv.hex", iv);
    $readmemh("tests/test_aes_ctr/aes128/plaintext.hex", plaintext);
    $readmemh("tests/test_aes_ctr/aes128/ciphertext.hex", ciphertext);
end
`endif

aes_ctr dut(
    .clk,
    .rst_n,
    .key_i,
    .key_valid_i,
    .key_ready_o,
    .iv_i,
    .iv_valid_i,
    .din_i,
    .din_valid_i,
    .din_ready_o,
    .dout_o,
    .dout_valid_o,
    .dout_ready_i
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

// Feed inputs
initial begin
    key_i        = 128'h0;
    key_valid_i  = 1'b0;
    iv_i         = 128'h0;
    iv_valid_i   = 1'b0;
    din_i        = 128'h0;
    din_valid_i  = 1'b0;
    dout_ready_i = 1'b1;

    wait (rst_n == 1'b1);
    @(posedge clk);

    // Configure key and IV
    key_i       = key[0];
    key_valid_i = 1'b1;
    iv_i        = iv[0];
    iv_valid_i  = 1'b1;
    @(posedge clk);
    key_valid_i = 1'b0;
    iv_valid_i  = 1'b0;
end

always @(*) begin
    din_valid_i = (i < `NUM_TESTS);
    din_i       = (i >= `NUM_TESTS) ? 128'h0 : plaintext[i];
end

always @(posedge clk) begin
    if (i < `NUM_TESTS && din_ready_o) begin
        i <= i + 1;
    end
end

// Check outputs
always @(posedge clk) begin
    if (dout_valid_o && dout_ready_i) begin
        if (dout_o !== ciphertext[recv]) begin
            $display("Mismatch at test %0d: expected %h, got %h", recv, ciphertext[recv], dout_o);
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
    $fsdbDumpfile("output/aes_ctr.fsdb");
    $fsdbDumpvars(0, tb);
    $fsdbDumpMDA();
    $fsdbDumpSVA();
end
`else
initial begin
    $dumpfile("output/aes_ctr.vcd");
    $dumpvars(0, tb);
end
`endif

endmodule
