/*
 * gf128_mul.sv
 * ------------
 * Description : GF(2^128) Multiplier Module
 */

module gf128_mul(
    input  logic         clk,
    input  logic         rst_n,

    input  logic [127:0] a_i,
    input  logic [127:0] b_i,
    input  logic         valid_i,

    output logic [127:0] product_o,
    output logic         valid_o
);

//////////////////////////////////////////////////////////////////////
// Register
//////////////////////////////////////////////////////////////////////

logic [127:0] product_reg;
logic         valid_reg;


//////////////////////////////////////////////////////////////////////
// Wire
//////////////////////////////////////////////////////////////////////

logic [255:0] karatsuba_out;
logic         karatsuba_out_valid;

logic [127:0] product;
logic         valid;

karatsuba_top u_karatsuba_top (
    .clk,
    .rst_n,
    .a_i      (a_i),
    .b_i      (b_i),
    .valid_i,
    .product_o(karatsuba_out),
    .valid_o  (karatsuba_out_valid)
);

gf128_reduce u_gf128_reduce (
    .data_i  (karatsuba_out),
    .valid_i (karatsuba_out_valid),
    .data_o  (product),
    .valid_o (valid)
);

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        product_reg <= 128'b0;
        valid_reg  <= 1'b0;
    end else begin
        product_reg <= product;
        valid_reg  <= valid;
    end
end

////////////////////////////////////////////////////////////////////////////////
// Output
////////////////////////////////////////////////////////////////////////////////

assign product_o = product_reg;
assign valid_o = valid_reg;

endmodule
