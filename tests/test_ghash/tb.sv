`timescale 1ps/1ps

`define CYCLE 10
`define MAX_CYCLES 1000
`define NUM_TESTS 1
`define M 5

module tb;

logic         clk;
logic         rst_n;
logic [127:0] din_i;
logic         din_valid_i;
logic         din_ready_o;
logic         last_i;
logic [127:0] h_i;
logic         h_valid_i;
logic         dout_valid_o;
logic [127:0] dout_o;

logic [127:0] din [`M-1:0];
logic [127:0] h [0:0];
logic [127:0] dout [0:0];

initial begin
    $readmemh("tests/test_ghash/din.hex", din);
    $readmemh("tests/test_ghash/h.hex", h);
    $readmemh("tests/test_ghash/dout.hex", dout);
end

int i = 0;
int recv = 0;
int error = 0;

ghash dut (
    .clk,
    .rst_n,
    .din_i,
    .din_valid_i,
    .din_ready_o,
    .last_i,
    .h_i,
    .h_valid_i,
    .dout_o,
    .dout_valid_o
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

// Feed config
initial begin
    h_i = 0;
    h_valid_i = 1'b0;

    wait (rst_n == 1'b1);
    @(posedge clk);

    h_i = h[0];
    h_valid_i = 1'b1;
    @(posedge clk);
    h_valid_i = 1'b0;
end

// Feed input data
always @(*) begin
    if (i < `M && din_ready_o) begin
        din_i = din[i];
        din_valid_i = 1'b1;
        last_i = (i == `M - 1) ? 1'b1 : 1'b0;
    end else begin
        din_i = 0;
        din_valid_i = 1'b0;
        last_i = 1'b0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        i <= 0;
    end else begin
        if (i < `M && din_ready_o) begin
            i <= i + 1;
        end
    end
end

always @(posedge clk) begin
    if (dout_valid_o) begin
        if (dout_o !== dout[recv]) begin
            $display("Error at test %0d: expected %h, got %h", recv, dout[recv], dout_o);
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
    $fsdbDumpfile("output/ghash.fsdb");
    $fsdbDumpvars(0, tb);
    $fsdbDumpMDA();
    $fsdbDumpSVA();
end
`else
initial begin
    $dumpfile("output/ghash.vcd");
    $dumpvars(0, tb);
end
`endif

endmodule
