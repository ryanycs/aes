/*
 * aes.sv
 * ------
 * Description: AES module
 *
 * Module Dependency Tree:
 * - aes.sv
 *   - round.sv
 *     - sub_bytes.sv
 *       - s_box.sv
 *     - shift_rows.sv
 *     - mix_columns.sv
 *     - add_round_key.sv
 */
`include "define.svh"

module aes(
    input  logic         clk,
    input  logic         rst_n,
    input  logic         en,

    input  logic         valid_i,
    input  logic [127:0] plaintext_i,
    input  logic [127:0] round_key_i [Nr:0],

    output logic         valid_o,
    output logic [127:0] ciphertext_o
);

// Output of each round
logic         round_valid [Nr:0];
logic [127:0] round_state [Nr:0];

add_round_key u_initial_add_round_key(
    .valid_i     (valid_i),
    .state_i     (plaintext_i),
    .round_key_i (round_key_i[0]),
    .valid_o     (round_valid[0]),
    .state_o     (round_state[0])
);

genvar i;
generate
    for (i = 0; i < Nr - 1; i = i + 1) begin : round_loop
        round u_round_i(
            .clk,
            .rst_n,
            .en,
            .valid_i     (round_valid[i]),
            .state_i     (round_state[i]),
            .round_key_i (round_key_i[i+1]),
            .valid_o     (round_valid[i+1]),
            .state_o     (round_state[i+1])
        );
    end

    round #(
        .FINAL(1)
    ) u_final_round(
        .clk,
        .rst_n,
        .en,
        .valid_i     (round_valid[Nr-1]),
        .state_i     (round_state[Nr-1]),
        .round_key_i (round_key_i[Nr]),
        .valid_o     (round_valid[Nr]),
        .state_o     (round_state[Nr])
    );
endgenerate

assign valid_o = round_valid[Nr];
assign ciphertext_o = round_state[Nr];

endmodule
