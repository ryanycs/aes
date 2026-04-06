/*
 * karatsuba_top.sv
 * ------------
 * Description : Karatsuba Multiplier Top Module
 */

module karatsuba_top #(
    parameter WIDTH = 128,
    parameter BASE_WIDTH = 16
)(
    input  logic               clk,
    input  logic               rst_n,

    input  logic [WIDTH-1:0]   a_i,
    input  logic [WIDTH-1:0]   b_i,
    input  logic               valid_i,

    output logic [2*WIDTH-1:0] product_o,
    output logic               valid_o
);

generate
    if (WIDTH == BASE_WIDTH) begin : base
        karatsuba_base #(
            .WIDTH(BASE_WIDTH)
        ) u_karatsuba_base (
            .clk,
            .rst_n,
            .a_i,
            .b_i,
            .valid_i,
            .product_o,
            .valid_o
        );
    end else begin : recursive
        karatsuba_stage #(
            .WIDTH(WIDTH)
        ) u_karatsuba_stage (
            .clk,
            .rst_n,
            .a_i,
            .b_i,
            .valid_i,
            .product_o,
            .valid_o
        );
    end
endgenerate

endmodule
