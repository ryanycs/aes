/*
 * karatsuba_base.sv
 * ----------
 * Description : Karatsuba Multiplier Base Module (GF(2^n) Multiplier without Reduction)
 */

module karatsuba_base #(
    parameter WIDTH = 8
)(
    input  logic               clk,
    input  logic               rst_n,

    input  logic [WIDTH-1:0]   a_i,
    input  logic [WIDTH-1:0]   b_i,
    input  logic               valid_i,

    output logic [2*WIDTH-1:0] product_o,
    output logic               valid_o
);

logic               valid_reg;
logic [2*WIDTH-1:0] product_reg;

logic [2*WIDTH-1:0] tmp;
logic [2*WIDTH-1:0] product_next;

always_comb begin
    product_next = { (2*WIDTH){1'b0} };
    tmp = { {WIDTH{1'b0}}, a_i };

    for (int i = 0; i < WIDTH; i = i + 1) begin
        if (b_i[i]) begin
            product_next = product_next ^ (tmp << i);
        end
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_reg <= 1'b0;
        product_reg <= 'h0;
    end else begin
        valid_reg <= valid_i;
        product_reg <= product_next;
    end
end

assign valid_o = valid_reg;
assign product_o = product_reg;

endmodule
