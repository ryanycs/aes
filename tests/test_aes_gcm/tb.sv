`timescale 1ns/10ps

`include "define.svh"

`define CYCLE 10
`define MAX_CYCLES 2000
`define NUM_TESTS 100

module tb;

// AES CTR port
logic                clk;
logic                rst_n;
logic                mode_i;
logic [KEY_SIZE-1:0] key_i;
logic                key_valid_i;
logic                key_ready_o;
logic [95:0]         iv_i;
logic                iv_valid_i;
logic [127:0]        din_i;
logic                din_valid_i;
logic                din_ready_o;
logic                din_last_i;
logic [127:0]        dout_o;
logic                dout_valid_o;
logic [127:0]        tag_o;
logic                tag_valid_o;

logic [KEY_SIZE-1:0] key        [0:0];
logic [127:0]        iv         [0:0];
logic [127:0]        plaintext  [`NUM_TESTS-1:0];
logic [127:0]        ciphertext [`NUM_TESTS-1:0];
logic [127:0]        tag        [0:0];

int i = 0;
int recv = 0;
int error = 0;

int tag_recv = 0;
int tag_error = 0;

int cycle = 0;

`ifdef AES192
initial begin
    $readmemh("tests/test_aes_gcm/aes192/key.hex", key);
    $readmemh("tests/test_aes_gcm/aes192/iv.hex", iv);
    $readmemh("tests/test_aes_gcm/aes192/plaintext.hex", plaintext);
    $readmemh("tests/test_aes_gcm/aes192/ciphertext.hex", ciphertext);
    $readmemh("tests/test_aes_gcm/aes192/tag.hex", tag);
end
`elsif AES256
initial begin
    $readmemh("tests/test_aes_gcm/aes256/key.hex", key);
    $readmemh("tests/test_aes_gcm/aes256/iv.hex", iv);
    $readmemh("tests/test_aes_gcm/aes256/plaintext.hex", plaintext);
    $readmemh("tests/test_aes_gcm/aes256/ciphertext.hex", ciphertext);
    $readmemh("tests/test_aes_gcm/aes256/tag.hex", tag);
end
`else
initial begin
    $readmemh("tests/test_aes_gcm/aes128/key.hex", key);
    $readmemh("tests/test_aes_gcm/aes128/iv.hex", iv);
    $readmemh("tests/test_aes_gcm/aes128/plaintext.hex", plaintext);
    $readmemh("tests/test_aes_gcm/aes128/ciphertext.hex", ciphertext);
    $readmemh("tests/test_aes_gcm/aes128/tag.hex", tag);
end
`endif

aes_gcm dut(
    .clk,
    .rst_n,
    .mode_i,
    .key_i,
    .key_valid_i,
    .key_ready_o,
    .iv_i,
    .iv_valid_i,
    .din_i,
    .din_valid_i,
    .din_ready_o,
    .din_last_i,
    .dout_o,
    .dout_valid_o,
    .tag_o,
    .tag_valid_o
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
    mode_i       = 1'b0;
    key_i        = 128'h0;
    key_valid_i  = 1'b0;
    iv_i         = 128'h0;
    iv_valid_i   = 1'b0;
    din_i        = 128'h0;
    din_valid_i  = 1'b0;

    wait (rst_n == 1'b1);
    @(posedge clk);

    // Test 1: Encryption
    $display("[Info] Test Encryption");
    // Configure key and IV
    key_i       = key[0];
    key_valid_i = 1'b1;
    iv_i        = iv[0];
    iv_valid_i  = 1'b1;
    @(posedge clk);
    key_valid_i = 1'b0;
    iv_valid_i  = 1'b0;
    @(posedge clk);

    wait (tag_valid_o == 1'b1);
    @(posedge clk);

    // Test 2: Decryption
    $display("[Info] Test Decryption");
    mode_i      = 1'b1;
    key_i       = key[0];
    key_valid_i = 1'b1;
    iv_i        = iv[0];
    iv_valid_i  = 1'b1;
    @(posedge clk);
    key_valid_i = 1'b0;
    iv_valid_i  = 1'b0;
end

always @(*) begin
    if (mode_i == 1'b0) begin // Encryption
        din_valid_i = (i < `NUM_TESTS) ? 1'b1 : 1'b0;
        din_i       = (i >= `NUM_TESTS) ? 128'h0 : plaintext[i];
        din_last_i  = (i == `NUM_TESTS-1);
    end else begin // Decryption
        din_valid_i = (i < `NUM_TESTS) ? 1'b1 : 1'b0;
        din_i       = (i >= `NUM_TESTS) ? 128'h0 : ciphertext[i];
        din_last_i  = (i == `NUM_TESTS-1);
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        i <= 0;
    end else begin
        if (i < `NUM_TESTS && din_ready_o) begin
            i <= i + 1;
        end else if (i >= `NUM_TESTS) begin
            i <= 0;
        end
    end
end

// Check outputs
always @(posedge clk) begin
    cycle = cycle + 1;

    if (dout_valid_o) begin
        case (mode_i)
            1'b0: begin // Encryption
                if (dout_o !== ciphertext[recv]) begin
                    $display("Ciphertext mismatch at test %0d: expected %h, got %h", recv, ciphertext[recv], dout_o);
                    error <= error + 1;
                end
            end
            1'b1: begin // Decryption
                if (dout_o !== plaintext[recv - 100]) begin
                    $display("Plaintext mismatch at test %0d: expected %h, got %h", recv, plaintext[recv], dout_o);
                    error <= error + 1;
                end
            end
        endcase
        recv <= recv + 1;
    end

    if (tag_valid_o) begin
        if (tag_o !== tag[0]) begin
            $display("Tag Mismatch at test %0d: expected %h, got %h", tag_recv, tag[0], tag_o);
            error <= error + 1;
        end
        tag_recv <= tag_recv + 1;
    end
end

initial begin
    wait (recv == `NUM_TESTS * 2 && tag_recv == 2);

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
    $display("Total cycles: %0d", cycle);
    $finish;
end

`ifdef FSDB
initial begin
    $fsdbDumpfile("output/aes_gcm.fsdb");
    $fsdbDumpvars(0, tb);
    $fsdbDumpMDA();
    $fsdbDumpSVA();
end
`else
initial begin
    $dumpfile("output/aes_gcm.vcd");
    $dumpvars(0, tb);
end
`endif

endmodule
