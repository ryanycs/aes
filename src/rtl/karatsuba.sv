/*
 * karatsuba.sv
 * ------------
 * Description : Karatsuba Multiplier Top Module
 */

module karatsuba #(
    parameter WIDTH = 128,
    parameter BASE_WIDTH = 8
)(
    input  logic               clk,
    input  logic               rst_n,

    input  logic               valid_i,
    input  logic [WIDTH-1:0]   a_i,
    input  logic [WIDTH-1:0]   b_i,

    output logic               valid_o,
    output logic [2*WIDTH-1:0] result_o
);

generate
    if (WIDTH == BASE_WIDTH) begin : base
        gf_mul #(
            .WIDTH(BASE_WIDTH)
        ) u_gf_mul (
            .valid_i  (valid_i),
            .a_i      (a_i),
            .b_i      (b_i),
            .valid_o  (valid_o),
            .result_o (result_o)
        );

    end else begin : recursive
        karatsuba_core #(
            .WIDTH(WIDTH)
        ) u_karatsuba_core (
            .clk,
            .rst_n,
            .valid_i,
            .a_i,
            .b_i,
            .valid_o,
            .result_o
        );
    end
endgenerate

endmodule
