module add_round_key(
    input  logic         valid_i,
    input  logic [127:0] state_i,
    input  logic [127:0] round_key_i,
    output logic         valid_o,
    output logic [127:0] state_o
);

assign valid_o = valid_i;
assign state_o = state_i ^ round_key_i;

endmodule
