/*
 * key_expansion.sv
 * ----------------
 * Description: Key Expansion Module
 */
`include "sub_word.sv"

module key_expansion(
    input  logic         clk,
    input  logic         rst_n,

    input  logic         valid_i,
    input  logic [127:0] key_i,

    output logic         valid_o,
    output logic [127:0] round_key_o [0:10]
);

//////////////////////////////////////////////////////////////////////
// FSM State
//////////////////////////////////////////////////////////////////////

typedef enum logic [1:0] {
    S_IDLE,
    S_SUB_WORD,
    S_EXPAND,
    S_DONE
} state_e;


//////////////////////////////////////////////////////////////////////
// Register
//////////////////////////////////////////////////////////////////////

state_e       state_reg;
logic [3:0]   round_idx_reg;
logic [127:0] round_key_reg [10:0];

logic [7:0]   rcon_reg;
logic [31:0]  temp_reg; // sub_word(rot_word(w3))


//////////////////////////////////////////////////////////////////////
// Wire
//////////////////////////////////////////////////////////////////////

state_e       state_next;
logic [127:0] round_key_prev;
logic [127:0] round_key_next;

logic [31:0]  temp;

logic [31:0]  w0_prev, w1_prev, w2_prev, w3_prev;
logic [31:0]  w0, w1, w2, w3;

logic [7:0]   rcon_next;

logic [31:0]  temp_xor_rcon; // temp ^ {rcon, 24'd0}


//////////////////////////////////////////////////////////////////////
// Function
//////////////////////////////////////////////////////////////////////

// Rotate word left by 1 byte (e.g., {a0,a1,a2,a3} -> {a1,a2,a3,a0})
function [31:0] rot_word(input [31:0] word);
    rot_word = {word[23:0], word[31:24]};
endfunction

// Multiply by x (i.e., 2) in GF(2^8)
function [7:0] xtime(input [7:0] n);
    if (n[7] == 1'b1)
        xtime = (n << 1) ^ 8'h1b;
    else
        xtime = n << 1;
endfunction


//////////////////////////////////////////////////////////////////////
// Combinational Logic
//////////////////////////////////////////////////////////////////////

sub_word u_sub_word(
    .word_i (rot_word(w3_prev)),
    .word_o (temp)
);

// FSM
always_comb begin
    case (state_reg)
        S_IDLE: begin
            state_next = valid_i ? S_SUB_WORD : S_IDLE;
        end

        S_SUB_WORD: begin
            state_next = S_EXPAND;
        end

        S_EXPAND: begin
            if (round_idx_reg == 4'd10) begin
                state_next = S_DONE;
            end else begin
                state_next = S_SUB_WORD;
            end
        end

        S_DONE: begin
            state_next = S_IDLE;
        end

        default: begin
            state_next = S_IDLE;
        end
    endcase
end

// rcon_next
always_comb begin
    if (state_reg == S_IDLE) begin
        rcon_next = 8'h01;
    end else if (state_reg == S_EXPAND) begin
        rcon_next = xtime(rcon_reg);
    end else begin
        rcon_next = rcon_reg;
    end
end

assign temp_xor_rcon = temp_reg ^ {rcon_reg, 24'd0};

// Unpack previous round key
assign round_key_prev = round_key_reg[round_idx_reg - 1];
assign {w0_prev, w1_prev, w2_prev, w3_prev} = round_key_prev;

// w0, w1, w2, w3
always_comb begin
    w0 = w0_prev ^ temp_xor_rcon;
    w1 = w1_prev ^ w0_prev ^ temp_xor_rcon;
    w2 = w2_prev ^ w1_prev ^ w0_prev ^ temp_xor_rcon;
    w3 = w3_prev ^ w2_prev ^ w1_prev ^ w0_prev ^ temp_xor_rcon;
end

// Pack next round key
assign round_key_next = {w0, w1, w2, w3};


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

// round_idx
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        round_idx_reg <= 4'd1;
    end else if (state_reg == S_EXPAND) begin
        round_idx_reg <= round_idx_reg + 4'd1;
    end else if (state_reg == S_SUB_WORD) begin
        round_idx_reg <= round_idx_reg;
    end else begin
        round_idx_reg <= 4'd1;
    end
end

// round_keys
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (int i = 0; i < 11; i = i + 1) begin
            round_key_reg[i] <= 128'd0;
        end
    end else if (state_reg == S_IDLE) begin
        if (valid_i)
            round_key_reg[0] <= key_i;

    end else if (state_reg == S_EXPAND) begin
        round_key_reg[round_idx_reg] <= round_key_next;
    end
end

// rcon
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rcon_reg <= 8'h01;
    end else begin
        rcon_reg <= rcon_next;
    end
end

// temp
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        temp_reg <= 32'd0;
    end else if (state_reg == S_SUB_WORD) begin
        temp_reg <= temp;
    end
end


//////////////////////////////////////////////////////////////////////
// Output
//////////////////////////////////////////////////////////////////////

assign valid_o = (state_reg == S_DONE);
assign round_key_o = round_key_reg;

endmodule
