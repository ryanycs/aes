/*
 * karatsuba_stage.sv
 * -----------------
 * Description : Karatsuba Multiplier Stage Module
 */

module karatsuba_stage #(
    parameter WIDTH = 128
)(
    input  logic               clk,
    input  logic               rst_n,

    input  logic [WIDTH-1:0]   a_i,
    input  logic [WIDTH-1:0]   b_i,
    input  logic               valid_i,

    output logic [2*WIDTH-1:0] product_o,
    output logic               valid_o
);

//////////////////////////////////////////////////////////////////////
// Parameter
//////////////////////////////////////////////////////////////////////

localparam ZERO_PAD      = {WIDTH{1'b0}};
localparam HALF_ZERO_PAD = {WIDTH/2{1'b0}};


//////////////////////////////////////////////////////////////////////
// Wire
//////////////////////////////////////////////////////////////////////

logic [WIDTH/2-1:0] a_lo, a_hi, b_lo, b_hi;

logic [WIDTH*2-1:0] product;

logic             z0_valid, z1_valid, z2_valid;
logic [WIDTH-1:0] z0, z1, z2;
logic             valid;


//////////////////////////////////////////////////////////////////////
// Instance
//////////////////////////////////////////////////////////////////////

assign a_lo = a_i[WIDTH/2-1:0];
assign a_hi = a_i[WIDTH-1:WIDTH/2];
assign b_lo = b_i[WIDTH/2-1:0];
assign b_hi = b_i[WIDTH-1:WIDTH/2];

// z0 = a_lo * b_lo
karatsuba_top #(
    .WIDTH(WIDTH/2)
) u_karatsuba_z0 (
    .clk,
    .rst_n,
    .a_i      (a_lo),
    .b_i      (b_lo),
    .valid_i,
    .product_o(z0),
    .valid_o  (z0_valid)
);

// z1 = (a_lo + a_hi) * (b_lo + b_hi)
karatsuba_top #(
    .WIDTH(WIDTH/2)
) u_karatsuba_z1 (
    .clk,
    .rst_n,
    .a_i      (a_lo ^ a_hi),
    .b_i      (b_lo ^ b_hi),
    .valid_i,
    .product_o(z1),
    .valid_o  (z1_valid)
);

// z2 = a_hi * b_hi
karatsuba_top #(
    .WIDTH(WIDTH/2)
) u_karatsuba_z2 (
    .clk,
    .rst_n,
    .a_i      (a_hi),
    .b_i      (b_hi),
    .valid_i,
    .product_o(z2),
    .valid_o  (z2_valid)
);

// valid when all z valid
assign valid = z0_valid & z1_valid & z2_valid;

// product = z2 << WIDTH + (z1 - z2 - z0) << (WIDTH/2) + z0
assign product = (
    { z2, ZERO_PAD } ^
    { HALF_ZERO_PAD, (z1 ^ z2 ^ z0), HALF_ZERO_PAD } ^
    { ZERO_PAD, z0 }
);


//////////////////////////////////////////////////////////////////////
// Output
//////////////////////////////////////////////////////////////////////

assign valid_o = valid;
assign product_o = product;

endmodule
