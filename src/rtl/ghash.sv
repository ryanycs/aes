/*
 * ghash.sv
 * --------
 * Description : GHASH Module
 */
// TODO: The ghash module currently not well support discontinuous input data stream

module ghash(
    input  logic         clk,
    input  logic         rst_n,

    input  logic [127:0] din_i,
    input  logic         din_valid_i,
    output logic         din_ready_o,
    input  logic         last_i,       // The last block of input data

    input  logic [127:0] h_i,
    input  logic         h_valid_i,

    output logic [127:0] dout_o,
    output logic         dout_valid_o
);

typedef enum logic [1:0] {
    S_IDLE,
    S_FIRST_BLOCK,
    S_STD_BLOCK,
    S_LAST_BLOCK
} state_e;

//////////////////////////////////////////////////////////////////////
// Register
//////////////////////////////////////////////////////////////////////

state_e       state_reg;
logic [127:0] h_reg;

logic         fifo_pop_reg;
logic [127:0] mul_output_reg;


//////////////////////////////////////////////////////////////////////
// Wire
//////////////////////////////////////////////////////////////////////

state_e       state_next;

logic         h_cfg_done;

logic         fifo_pop;
logic [128:0] fifo_output;
logic         fifo_empty;
logic         fifo_full;
logic         fifo_almost_empty;
logic         fifo_almost_full;

logic         mul_input_valid;
logic [127:0] mul_input;
logic         mul_output_valid;
logic [127:0] mul_output;

function [127:0] reverse(input [127:0] n);
    for (int i = 0; i < 128; i++) begin
        reverse[i] = n[127 - i];
    end
endfunction


//////////////////////////////////////////////////////////////////////
// Instance
//////////////////////////////////////////////////////////////////////

fifo #(
    .DATA_WIDTH(129)
) u_fifo (
    .clk,
    .rst_n,
    .push_i         (din_valid_i),
    .data_i         ({last_i, reverse(din_i)}),
    .pop_i          (fifo_pop),
    .data_o         (fifo_output),
    .empty_o        (fifo_empty),
    .full_o         (fifo_full),
    .almost_empty_o (fifo_almost_empty),
    .almost_full_o  (fifo_almost_full)
);

// TODO: Using en to stall the multiplier not a good practice
gf128_mul u_gf128_mul (
    .clk,
    .rst_n,
    .en       (!fifo_empty || mul_input_valid || state_reg != S_STD_BLOCK),
    .valid_i  (mul_input_valid),
    .a_i      (mul_input),
    .b_i      (h_reg),
    .valid_o  (mul_output_valid),
    .result_o (mul_output)
);
assign mul_input_valid = fifo_pop_reg;


//////////////////////////////////////////////////////////////////////
// Combinational Logic
//////////////////////////////////////////////////////////////////////

// FSM
always_comb begin
    case (state_reg)
        S_IDLE:
            state_next = h_valid_i ? S_FIRST_BLOCK : S_IDLE;

        S_FIRST_BLOCK:
            state_next = !fifo_empty ? S_STD_BLOCK : S_FIRST_BLOCK;

        S_STD_BLOCK:
            state_next = fifo_output[128] ? S_LAST_BLOCK : S_STD_BLOCK;

        S_LAST_BLOCK:
            state_next = mul_output_valid ? S_IDLE : S_LAST_BLOCK;

        default:
            state_next = S_IDLE;
    endcase
end

// fifo_pop, mul_input
always_comb begin
    fifo_pop = 1'b0;
    mul_input = 128'h0;

    case (state_reg)
        S_FIRST_BLOCK: begin
            fifo_pop = !fifo_empty;
            mul_input = fifo_output[127:0];
        end

        S_STD_BLOCK: begin
            fifo_pop = !fifo_empty & mul_output_valid;
            mul_input = fifo_output[127:0] ^ mul_output_reg;
        end
    endcase
end


//////////////////////////////////////////////////////////////////////
// Sequential Logic
//////////////////////////////////////////////////////////////////////

// state
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_reg <= S_IDLE;
    end else begin
        state_reg <= state_next;
    end
end

// fifo_pop_reg
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        fifo_pop_reg <= 1'b0;
    end else begin
        fifo_pop_reg <= fifo_pop;
    end
end

// mul_output_reg
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mul_output_reg <= 128'h0;
    end else begin
        if (state_reg == S_IDLE)
            mul_output_reg <= 128'h0;

        else if (mul_output_valid)
            mul_output_reg <= mul_output;
    end
end

// h
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        h_reg <= 128'h0;
    end else begin
        if (h_valid_i)
            h_reg <= reverse(h_i);
    end
end

// h_cfg_done
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        h_cfg_done <= 1'b0;
    end else begin
        if (h_valid_i)
            h_cfg_done <= 1'b1;
    end
end


//////////////////////////////////////////////////////////////////////
// Output Logic
//////////////////////////////////////////////////////////////////////

assign din_ready_o  = (!fifo_almost_full) & h_cfg_done;
assign dout_o       = reverse(mul_output);
assign dout_valid_o = (state_reg == S_LAST_BLOCK) & mul_output_valid;

endmodule
