`include "s_box.sv"

module sub_bytes(
    input  logic         clk,
    input  logic         rst_n,
    input  logic         en,

    input  logic         valid_i,
    input  logic [127:0] state_i,

    output logic         valid_o,
    output logic [127:0] state_o
);

logic [127:0] s_box_out;
logic [127:0] state_reg;

genvar i;
generate
    for (i = 0; i < 16; i = i + 1) begin : s_box_loop
        s_box u_s_box(
            .data_i (state_i[i*8 +: 8]),
            .data_o (s_box_out[i*8 +: 8])
        );
    end
endgenerate

// state_reg
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_reg <= 128'd0;
    end else if (en) begin
        state_reg <= s_box_out;
    end
end

// out_valid
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
    end else if (en) begin
        valid_o <= valid_i;
    end
end

assign state_o = state_reg;

endmodule
