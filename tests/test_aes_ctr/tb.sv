`timescale 1ns/10ps
`define CYCLE 10
`define MAX_CYCLES 1000
`define NUM_TESTS 4

module tb;

// AES CTR port
logic         clk;
logic         rst_n;
logic [127:0] key_i;
logic         key_valid_i;
logic         key_ready_o;
logic [127:0] iv_i;
logic         iv_valid_i;
logic [127:0] din_i;
logic         din_valid_i;
logic         din_ready_o;
logic [127:0] dout_o;
logic         dout_valid_o;

logic [127:0] input_key         [0:0];
logic [127:0] input_iv          [0:0];
logic [127:0] input_plaintext   [`NUM_TESTS-1:0];
logic [127:0] golden_ciphertext [`NUM_TESTS-1:0];

int i = 0;
int recv = 0;
int error = 0;

initial begin
    $readmemh("tests/test_aes_ctr/key.hex", input_key);
    $readmemh("tests/test_aes_ctr/iv.hex", input_iv);
    $readmemh("tests/test_aes_ctr/input.hex", input_plaintext);
    $readmemh("tests/test_aes_ctr/golden.hex", golden_ciphertext);
end

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
    .dout_valid_o
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
initial begin
    key_i        = 128'h0;
    key_valid_i  = 1'b0;
    iv_i         = 128'h0;
    iv_valid_i   = 1'b0;
    din_i        = 128'h0;
    din_valid_i  = 1'b0;

    wait (rst_n == 1'b1);
    @(posedge clk);

    // Configure key and IV
    key_i       = input_key[0];
    key_valid_i = 1'b1;
    iv_i       = input_iv[0];
    iv_valid_i = 1'b1;
    @(posedge clk);
    key_valid_i = 1'b0;
    iv_valid_i = 1'b0;

    // Feed plaintexts
    wait (din_ready_o == 1'b1);
    while (i < `NUM_TESTS) begin
        if ($urandom_range(0,1) == 1) begin  // Randomly skip sending input data
            din_valid_i = 1'b0;
        end else begin
            din_valid_i = 1'b1;
            din_i       = input_plaintext[i];
            i           = i + 1;
        end
        @(posedge clk);
    end

    din_valid_i = 1'b0;
end

// Check outputs
always @(posedge clk) begin
    if (dout_valid_o) begin
        if (dout_o !== golden_ciphertext[recv]) begin
            $display("Mismatch at test %0d: expected %h, got %h", recv, golden_ciphertext[recv], dout_o);
            error = error + 1;
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
