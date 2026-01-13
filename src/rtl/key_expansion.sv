/*
 * key_expansion.sv
 * ----------------
 * Description: Key Expansion Module
 */
`include "define.svh"

module key_expansion(
    input  logic                clk,
    input  logic                rst_n,

    input  logic                valid_i,
    output logic                ready_o,
    input  logic [KEY_SIZE-1:0] key_i,

    output logic                valid_o,
    output logic [127:0]        round_key_o [Nr:0]
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
logic [5:0]   idx_reg;
logic [31:0]  w_reg [Nb * (Nr + 1) - 1:0];

logic [7:0]   rcon_reg;
logic [31:0]  temp_reg; // sub_word(rot_word(w3))


//////////////////////////////////////////////////////////////////////
// Wire
//////////////////////////////////////////////////////////////////////

state_e      state_next;

logic [31:0] w_next [Nk - 1:0];

logic [7:0]  rcon_next;

logic [31:0] sub_word_in;

logic [31:0] temp;
logic [31:0] temp_xor_rcon; // temp ^ {rcon, 24'd0}


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
    .word_i (sub_word_in),
    .word_o (temp)
);
`ifdef AES256
assign sub_word_in = (idx_reg[2:0] == 3'b0) ?
                     rot_word(w_reg[idx_reg - 1]) : w_reg[idx_reg - 1];
`else
assign sub_word_in = rot_word(w_reg[idx_reg - 1]);
`endif

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
            if (idx_reg >= Nb * (Nr + 1)) begin
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
        `ifdef AES256
        rcon_next = (idx_reg[2:0] == 3'd0) ? xtime(rcon_reg) : rcon_reg;
        `else
        rcon_next = xtime(rcon_reg);
        `endif
    end else begin
        rcon_next = rcon_reg;
    end
end

assign temp_xor_rcon = temp_reg ^ {rcon_reg, 24'd0};

// w_next
always_comb begin
    `ifdef AES256
    if (idx_reg[2:0] == 3'd0)
        w_next[0] = w_reg[idx_reg - Nk] ^ temp_xor_rcon;
    else
        w_next[0] = w_reg[idx_reg - Nk] ^ temp;
    `else
        w_next[0] = w_reg[idx_reg - Nk] ^ temp_xor_rcon;
    `endif

    for (int i = 1; i < EXP_PER_CYCLE; i = i + 1) begin
        w_next[i] = w_reg[idx_reg - Nk + i[5:0]] ^ w_next[i - 1];
    end
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

// idx
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        idx_reg <= Nk;

    end else if (state_reg == S_EXPAND) begin
        idx_reg <= idx_reg + EXP_PER_CYCLE;

    end else if (state_reg == S_SUB_WORD) begin
        idx_reg <= idx_reg;

    end else begin
        idx_reg <= Nk;

    end
end

// w
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (int i = 0; i < Nb * (Nr + 1); i = i + 1) begin
            w_reg[i] <= 32'd0;
        end
    end else if (state_reg == S_IDLE) begin
        if (valid_i)
            for (int i = 0; i < Nk; i = i + 1) begin
                w_reg[i] <= key_i[(KEY_SIZE - i * 32 - 1) -: 32];
            end

    end else if (state_reg == S_EXPAND) begin
        for (int i = 0; i < EXP_PER_CYCLE; i = i + 1) begin
            w_reg[idx_reg + i[5:0]] <= w_next[i];
        end
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
assign ready_o = (state_reg == S_IDLE);

genvar i;
generate
    for (i = 0; i <= Nr; i = i + 1) begin
        assign round_key_o[i] = {
            w_reg[i * Nb],
            w_reg[i * Nb + 1],
            w_reg[i * Nb + 2],
            w_reg[i * Nb + 3]
        };
    end
endgenerate

endmodule
