/*
 * gf_mul.sv
 * ----------
 * Description : Galois Field Multiplier Module (without reduction)
 */

module gf_mul #(
    parameter WIDTH = 8
)(
    input  logic               valid_i,
    input  logic [WIDTH-1:0]   a_i,
    input  logic [WIDTH-1:0]   b_i,

    output logic               valid_o,
    output logic [2*WIDTH-1:0] result_o
);

logic [2*WIDTH-1:0] tmp;
logic [2*WIDTH-1:0] result;

always_comb begin
    result = { (2*WIDTH){1'b0} };
    tmp = { {WIDTH{1'b0}}, a_i };

    for (int i = 0; i < WIDTH; i = i + 1) begin
        if (b_i[i]) begin
            result = result ^ (tmp << i);
        end
    end
end

assign valid_o = valid_i;
assign result_o = result;

endmodule
