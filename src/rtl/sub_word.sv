/*
 * sub_word.sv
 * -----------
 */

module sub_word(
    input  logic [31:0] word_i,
    output logic [31:0] word_o
);

genvar i;
generate
    for (i = 0; i < 4; i = i + 1) begin
        s_box u_s_box(
            .data_i (word_i[8*i +: 8]),
            .data_o (word_o[8*i +: 8])
        );
    end
endgenerate

endmodule
