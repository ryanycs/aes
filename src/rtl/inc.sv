/*
 * inc.sv
 * ------
 */

module inc #(
    parameter s = 32
)(
    input  logic [127:0] data_i,
    output logic [127:0] data_o
);

logic [s-1:0] one = { {s-1{1'b0}}, 1'b1 };

assign data_o = {data_i[127:s], data_i[s-1:0] + one};

endmodule
