`include "sub_bytes.sv"
`include "shift_rows.sv"
`include "mix_columns.sv"
`include "add_round_key.sv"

module round #(
    parameter FINAL = 0
)(
    input  logic         clk,
    input  logic         rst_n,
    input  logic         valid_i,
    input  logic [127:0] state_i,
    input  logic [127:0] round_key_i,
    output logic         valid_o,
    output logic [127:0] state_o
);

logic         sub_bytes_valid;
logic [127:0] sub_bytes_out;

logic         shift_rows_valid;
logic [127:0] shift_rows_out;

logic         mix_columns_valid;
logic [127:0] mix_columns_out;

sub_bytes u_sub_bytes(
    .clk,
    .rst_n,
    .valid_i (valid_i),
    .state_i (state_i),
    .valid_o (sub_bytes_valid),
    .state_o (sub_bytes_out)
);

shift_rows u_shift_rows(
    .valid_i (sub_bytes_valid),
    .state_i (sub_bytes_out),
    .valid_o (shift_rows_valid),
    .state_o (shift_rows_out)
);

generate
    if (FINAL) begin : final_round
        add_round_key u_add_round_key(
            .valid_i     (shift_rows_valid),
            .state_i     (shift_rows_out),
            .round_key_i (round_key_i),
            .valid_o     (valid_o),
            .state_o     (state_o)
        );
    end else begin : normal_round
        mix_columns u_mix_columns(
            .clk,
            .rst_n,
            .valid_i (shift_rows_valid),
            .state_i (shift_rows_out),
            .valid_o (mix_columns_valid),
            .state_o (mix_columns_out)
        );

        add_round_key u_add_round_key(
            .valid_i     (mix_columns_valid),
            .state_i     (mix_columns_out),
            .round_key_i (round_key_i),
            .valid_o     (valid_o),
            .state_o     (state_o)
        );
    end
endgenerate

endmodule
