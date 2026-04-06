/*
 * ghash.sv
 * --------
 * Description : GHASH Module
 */

module ghash(
    input  logic         clk,
    input  logic         rst_n,

    input  logic [127:0] h_i,
    input  logic         h_valid_i,
    output logic         h_ready_o,

    input  logic [127:0] din_i,
    input  logic         din_last_i,
    input  logic         din_valid_i,
    output logic         din_ready_o,

    output logic [127:0] dout_o,
    output logic         dout_valid_o,
    input  logic         dout_ready_i
);

typedef enum logic [3:0] {
    S_IDLE,
    S_CALC_H2,
    S_WAIT_H2,
    S_CALC_H3_H4,
    S_WAIT_H3_H4,
    S_GHASH_FIRST,
    S_GHASH,
    S_WAIT_GHASH,
    S_GHASH_LAST,
    S_WAIT_GHASH_LAST,
    S_DONE
} state_e;

logic [127:0] in_reg [3:0];
logic [1:0]   cnt_reg;
logic [1:0]   cnt_last_reg;

logic [127:0] h_reg;
logic [127:0] h2_reg;
logic [127:0] h3_reg;
logic [127:0] h4_reg;

state_e state_reg;
state_e state_next;

// mul1
logic [127:0] mul1_a;
logic [127:0] mul1_b;
logic         mul1_in_valid;
logic [127:0] mul1_out;
logic         mul1_out_valid;

// mul2
logic [127:0] mul2_a;
logic [127:0] mul2_b;
logic         mul2_in_valid;
logic [127:0] mul2_out;
logic         mul2_out_valid;

// mul3
logic [127:0] mul3_a;
logic [127:0] mul3_b;
logic         mul3_in_valid;
logic [127:0] mul3_out;
logic         mul3_out_valid;

// mul4
logic [127:0] mul4_a;
logic [127:0] mul4_b;
logic         mul4_in_valid;
logic [127:0] mul4_out;
logic         mul4_out_valid;

logic din_handshake;
assign din_handshake = din_valid_i && din_ready_o;

logic [127:0] sum_reg;
logic [127:0] sum_next;
assign sum_next = mul1_out ^ mul2_out ^ mul3_out ^ mul4_out;

////////////////////////////////////////////////////////////////////////////////
// Function
////////////////////////////////////////////////////////////////////////////////

function [127:0] reverse(input [127:0] n);
    for (int i = 0; i < 128; i = i + 1) begin
        reverse[i] = n[127 - i];
    end
endfunction

////////////////////////////////////////////////////////////////////////////////
// Instance
////////////////////////////////////////////////////////////////////////////////

gf128_mul u_gf128_mul1(
    .clk,
    .rst_n,
    .a_i      (mul1_a),
    .b_i      (mul1_b),
    .valid_i  (mul1_in_valid),
    .product_o(mul1_out),
    .valid_o  (mul1_out_valid)
);

gf128_mul u_gf128_mul2(
    .clk,
    .rst_n,
    .a_i      (mul2_a),
    .b_i      (mul2_b),
    .valid_i  (mul2_in_valid),
    .product_o(mul2_out),
    .valid_o  (mul2_out_valid)
);

gf128_mul u_gf128_mul3(
    .clk,
    .rst_n,
    .a_i      (mul3_a),
    .b_i      (mul3_b),
    .valid_i  (mul3_in_valid),
    .product_o(mul3_out),
    .valid_o  (mul3_out_valid)
);

gf128_mul u_gf128_mul4(
    .clk,
    .rst_n,
    .a_i      (mul4_a),
    .b_i      (mul4_b),
    .valid_i  (mul4_in_valid),
    .product_o(mul4_out),
    .valid_o  (mul4_out_valid)
);


////////////////////////////////////////////////////////////////////////////////
// Control
////////////////////////////////////////////////////////////////////////////////

// FSM
always_comb begin
    case (state_reg)
        S_IDLE:
            state_next = h_valid_i ? S_CALC_H2 : S_IDLE;

        S_CALC_H2:
            state_next = S_WAIT_H2;

        S_WAIT_H2:
            state_next = mul1_out_valid ? S_CALC_H3_H4 : S_WAIT_H2;

        S_CALC_H3_H4:
            state_next = S_WAIT_H3_H4;

        S_WAIT_H3_H4:
            state_next = mul1_out_valid ? S_GHASH_FIRST : S_WAIT_H3_H4;

        S_GHASH_FIRST:
            if (din_last_i && din_handshake) // The last block is also the first block
                state_next = S_GHASH_LAST;
            else if (cnt_reg == 2'd3)
                state_next = S_GHASH;
            else
                state_next = S_GHASH_FIRST;

        S_GHASH:
            if (din_last_i && din_handshake)
                state_next = (cnt_reg == 2'd3) ? S_GHASH_LAST : S_WAIT_GHASH;
            else
                state_next = S_GHASH;

        // Wait for the multiplier to start processing the last block
        S_WAIT_GHASH:
            state_next = (cnt_reg == 2'd3) ? S_GHASH_LAST : S_WAIT_GHASH;

        S_GHASH_LAST:
            state_next = S_WAIT_GHASH_LAST;

        S_WAIT_GHASH_LAST:
            state_next = mul1_out_valid ? S_DONE : S_WAIT_GHASH_LAST;

        S_DONE:
            state_next = dout_ready_i ? S_IDLE : S_DONE;

        default:
            state_next = S_IDLE;
    endcase
end

// mul Control
always_comb begin
    mul1_a        = 128'h0;
    mul1_b        = 128'h0;
    mul1_in_valid = 1'b0;

    mul2_a        = 128'h0;
    mul2_b        = 128'h0;
    mul2_in_valid = 1'b0;

    mul3_a        = 128'h0;
    mul3_b        = 128'h0;
    mul3_in_valid = 1'b0;

    mul4_a        = 128'h0;
    mul4_b        = 128'h0;
    mul4_in_valid = 1'b0;

    case (state_reg)
        S_CALC_H2: begin
            mul1_a        = h_reg;
            mul1_b        = h_reg;
            mul1_in_valid = 1'b1;
        end

        S_CALC_H3_H4: begin
            mul1_a        = h_reg;
            mul1_b        = h2_reg;
            mul1_in_valid = 1'b1;

            mul2_a        = h2_reg;
            mul2_b        = h2_reg;
            mul2_in_valid = 1'b1;
        end

        S_GHASH, S_WAIT_GHASH: begin
            mul1_a        = in_reg[0] ^ sum_reg;
            mul1_b        = h4_reg;
            mul1_in_valid = (cnt_reg == 2'd0);

            mul2_a        = in_reg[1];
            mul2_b        = h3_reg;
            mul2_in_valid = (cnt_reg == 2'd0);

            mul3_a        = in_reg[2];
            mul3_b        = h2_reg;
            mul3_in_valid = (cnt_reg == 2'd0);

            mul4_a        = in_reg[3];
            mul4_b        = h_reg;
            mul4_in_valid = (cnt_reg == 2'd0);
        end

        S_GHASH_LAST: begin
            case (cnt_last_reg)
                2'd0: begin
                    mul1_a        = in_reg[0] ^ sum_reg;
                    mul1_b        = h_reg;
                    mul1_in_valid = 1'b1;
                end

                2'd1: begin
                    mul1_a        = in_reg[0] ^ sum_reg;
                    mul1_b        = h2_reg;
                    mul1_in_valid = 1'b1;

                    mul2_a        = in_reg[1];
                    mul2_b        = h_reg;
                    mul2_in_valid = 1'b1;
                end

                2'd2: begin
                    mul1_a        = in_reg[0] ^ sum_reg;
                    mul1_b        = h3_reg;
                    mul1_in_valid = 1'b1;

                    mul2_a        = in_reg[1];
                    mul2_b        = h2_reg;
                    mul2_in_valid = 1'b1;

                    mul3_a        = in_reg[2];
                    mul3_b        = h_reg;
                    mul3_in_valid = 1'b1;
                end

                2'd3: begin
                    mul1_a        = in_reg[0] ^ sum_reg;
                    mul1_b        = h4_reg;
                    mul1_in_valid = 1'b1;

                    mul2_a        = in_reg[1];
                    mul2_b        = h3_reg;
                    mul2_in_valid = 1'b1;

                    mul3_a        = in_reg[2];
                    mul3_b        = h2_reg;
                    mul3_in_valid = 1'b1;

                    mul4_a        = in_reg[3];
                    mul4_b        = h_reg;
                    mul4_in_valid = 1'b1;
                end
            endcase
        end
    endcase
end

// state
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_reg <= S_IDLE;
    end else begin
        state_reg <= state_next;
    end
end

// h
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        h_reg <= 128'h0;
    end else if (h_valid_i && state_reg == S_IDLE) begin
        h_reg <= reverse(h_i);
    end
end

// h2
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        h2_reg <= 128'h0;
    end else if (state_reg == S_WAIT_H2 && mul1_out_valid) begin
        h2_reg <= mul1_out;
    end
end

// h3, h4
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        h3_reg <= 128'h0;
        h4_reg <= 128'h0;
    end else if (state_reg == S_WAIT_H3_H4 && mul1_out_valid) begin
        h3_reg <= mul1_out;
        h4_reg <= mul2_out;
    end
end

// input buffer
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (int j = 0; j < 4; j++) begin
            in_reg[j] <= 128'h0;
        end
    end else if (din_handshake) begin
        in_reg[cnt_reg] <= reverse(din_i);
    end
end

// cnt
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt_reg <= 2'd0;
    end else if (state_reg == S_IDLE) begin
        cnt_reg <= 2'd0;
    end else if (din_handshake) begin
        cnt_reg <= cnt_reg + 1;
    end else if (state_reg == S_WAIT_GHASH) begin
        cnt_reg <= cnt_reg + 1;
    end
end

// cnt_last
//   Buffer the count of the last block, used to determine
//   how to process the last batch
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt_last_reg <= 2'd0;
    end else if (din_last_i && din_handshake) begin
        cnt_last_reg <= cnt_reg;
    end
end

// sum
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sum_reg <= 128'h0;
    end else if (state_reg == S_WAIT_H3_H4) begin
        sum_reg <= 128'h0;
    end else if (mul1_out_valid) begin
        sum_reg <= sum_next;
    end
end

////////////////////////////////////////////////////////////////////////////////
// Output
////////////////////////////////////////////////////////////////////////////////

assign h_ready_o = (state_reg == S_IDLE);

assign din_ready_o  = (
    state_reg == S_GHASH
    || state_reg == S_GHASH_FIRST
);

assign dout_o       = reverse(sum_reg);
assign dout_valid_o = (state_reg == S_DONE);

endmodule
