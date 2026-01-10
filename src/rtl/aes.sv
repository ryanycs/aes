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

module aes(
    input  logic         clk,
    input  logic         rst_n,
    input  logic         en,

    input  logic         valid_i,
    input  logic [127:0] plaintext_i,
    input  logic [127:0] round_key_i [10:0],

    output logic         valid_o,
    output logic [127:0] ciphertext_o
);

// Output of each round
logic         round_valid [10:0];
logic [127:0] round_state [10:0];

add_round_key u_initial_add_round_key(
    .valid_i     (valid_i),
    .state_i     (plaintext_i),
    .round_key_i (round_key_i[0]),
    .valid_o     (round_valid[0]),
    .state_o     (round_state[0])
);

genvar i;
generate
    for (i = 0; i < 9; i = i + 1) begin : round_loop
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
        .valid_i     (round_valid[9]),
        .state_i     (round_state[9]),
        .round_key_i (round_key_i[10]),
        .valid_o     (round_valid[10]),
        .state_o     (round_state[10])
    );
endgenerate

assign valid_o = round_valid[10];
assign ciphertext_o = round_state[10];

endmodule
