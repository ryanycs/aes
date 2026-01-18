/*
 * gf128_mul.sv
 * ------------
 * Description : GF(2^128) Multiplier Module
 */

module gf128_mul(
    input  logic         clk,
    input  logic         rst_n,
    input  logic         en,

    input  logic         valid_i,
    input  logic [127:0] a_i,
    input  logic [127:0] b_i,

    output logic         valid_o,
    output logic [127:0] result_o
);

//////////////////////////////////////////////////////////////////////
// Register
//////////////////////////////////////////////////////////////////////

logic         valid_reg;
logic [127:0] result_reg;

//////////////////////////////////////////////////////////////////////
// Wire
//////////////////////////////////////////////////////////////////////

logic         karatsuba_out_valid;
logic [255:0] karatsuba_out;

karatsuba u_karatsuba (
    .clk,
    .rst_n,
    .en,
    .valid_i,
    .a_i      (a_i),
    .b_i      (b_i),
    .valid_o  (karatsuba_out_valid),
    .result_o (karatsuba_out)
);

gf128_reduction u_gf128_reduction (
    .valid_i (karatsuba_out_valid),
    .data_i  (karatsuba_out),
    .valid_o (valid_o),
    .data_o  (result_o)
);

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_reg  <= 1'b0;
        result_reg <= 128'b0;
    end else if (en) begin
        valid_reg  <= valid_o;
        result_reg <= result_o;
    end
end

endmodule
