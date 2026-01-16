/*
 * karatsuba_core.sv
 * -----------------
 * Description : Karatsuba Multiplier Core Module
 */

module karatsuba_core #(
    parameter WIDTH = 128
)(
    input  logic               clk,
    input  logic               rst_n,

    input  logic               valid_i,
    input  logic [WIDTH-1:0]   a_i,
    input  logic [WIDTH-1:0]   b_i,

    output logic               valid_o,
    output logic [2*WIDTH-1:0] result_o
);

//////////////////////////////////////////////////////////////////////
// Parameter
//////////////////////////////////////////////////////////////////////

localparam ZERO_PAD      = {WIDTH{1'b0}};
localparam HALF_ZERO_PAD = {WIDTH/2{1'b0}};


//////////////////////////////////////////////////////////////////////
// Register
//////////////////////////////////////////////////////////////////////

logic               valid_reg;
logic [2*WIDTH-1:0] result_reg;


//////////////////////////////////////////////////////////////////////
// Wire
//////////////////////////////////////////////////////////////////////

logic [WIDTH/2-1:0] a_lo, a_hi, b_lo, b_hi;

logic [WIDTH*2-1:0] result_next;

logic             z0_valid, z1_valid, z2_valid;
logic [WIDTH-1:0] z0, z1, z2;
logic             result_valid;


//////////////////////////////////////////////////////////////////////
// Instance
//////////////////////////////////////////////////////////////////////

assign a_lo = a_i[WIDTH/2-1:0];
assign a_hi = a_i[WIDTH-1:WIDTH/2];
assign b_lo = b_i[WIDTH/2-1:0];
assign b_hi = b_i[WIDTH-1:WIDTH/2];

// z0 = a_lo * b_lo
karatsuba #(
    .WIDTH(WIDTH/2)
) u_karatsuba_z0 (
    .clk,
    .rst_n,
    .valid_i,
    .a_i      (a_lo),
    .b_i      (b_lo),
    .valid_o  (z0_valid),
    .result_o (z0)
);

// z1 = (a_lo + a_hi) * (b_lo + b_hi)
karatsuba #(
    .WIDTH(WIDTH/2)
) u_karatsuba_z1 (
    .clk,
    .rst_n,
    .valid_i,
    .a_i      (a_lo ^ a_hi),
    .b_i      (b_lo ^ b_hi),
    .valid_o  (z1_valid),
    .result_o (z1)
);

// z2 = a_hi * b_hi
karatsuba #(
    .WIDTH(WIDTH/2)
) u_karatsuba_z2 (
    .clk,
    .rst_n,
    .valid_i,
    .a_i      (a_hi),
    .b_i      (b_hi),
    .valid_o  (z2_valid),
    .result_o (z2)
);

// result valid when all z valid
assign result_valid = z0_valid & z1_valid & z2_valid;

// result = z2 << WIDTH + (z1 - z2 - z0) << (WIDTH/2) + z0
assign result_next = (
    { z2, ZERO_PAD } ^
    { HALF_ZERO_PAD, (z1 ^ z2 ^ z0), HALF_ZERO_PAD } ^
    { ZERO_PAD, z0 }
);

// result_reg
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        result_reg <= { (2*WIDTH){1'b0} };
    end else begin
        if (result_valid) begin
            result_reg <= result_next;
        end
    end
end

// valid_reg
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_reg <= 1'b0;
    end else begin
        valid_reg <= result_valid;
    end
end

//////////////////////////////////////////////////////////////////////
// Output
//////////////////////////////////////////////////////////////////////

assign valid_o = valid_reg;
assign result_o = result_reg;

endmodule
