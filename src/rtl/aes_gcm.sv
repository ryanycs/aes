/*
 * aes_gcm.sv
 * ----------
 * Description : AES-GCM Module
 */
`include "define.svh"

module aes_gcm(
    input  logic                clk,
    input  logic                rst_n,

    input  logic                mode_i,       // 0: Encrypt, 1: Decrypt

    // Key
    input  logic [KEY_SIZE-1:0] key_i,
    input  logic                key_valid_i,
    output logic                key_ready_o,

    // IV (Initialization Vector)
    input  logic [95:0]         iv_i,         // 96-bit IV for AES GCM
    input  logic                iv_valid_i,

    // Data Input/Output
    input  logic [127:0]        din_i,
    input  logic                din_valid_i,
    output logic                din_ready_o,
    input  logic                din_last_i,   // The last block of streaming input data

    output logic [127:0]        dout_o,
    output logic                dout_valid_o,

    // Authentication Tag
    output logic [127:0]        tag_o,
    output logic                tag_valid_o
);

localparam ENCRYPT = 1'b0;

//////////////////////////////////////////////////////////////////////
// FSM State
//////////////////////////////////////////////////////////////////////

typedef enum logic [4:0] {
    S_IDLE,

    S_H_SETUP,         // Setup IV = 0 to calculate H
    S_H_CALC,          // Set din = 0 to calculate H = AES_K(0)
    S_H_WAIT,          // Wait for aes_ctr output

    S_DATA_SETUP,      // Setup IV = {iv^96 || 2^32}
    S_DATA_PROCESS,    // Process input data
    S_DATA_LAST,

    S_GHASH_LEN,       // GHASH(A || C || len(A) || len(C))
    S_GHASH_LEN_WAIT,  // Wait for GHASH output

    S_TAG_SETUP,       // Setup iv = {iv^96 || 1^32}
    S_TAG_CALC,        // Calculate tag = GCTR(J0, GHASH(X))

    S_DONE
} state_e;


//////////////////////////////////////////////////////////////////////
// Register
//////////////////////////////////////////////////////////////////////

state_e state_reg;

logic [56:0]  block_count_reg;

logic [95:0]  iv_reg;
logic         iv_cfg_done_reg;

logic [127:0] din_reg;
logic         din_valid_reg;

logic [127:0] ghash_result_reg;

//////////////////////////////////////////////////////////////////////
// Wire
//////////////////////////////////////////////////////////////////////

state_e state_next;

// AES-CTR signal
logic [KEY_SIZE-1:0] aes_ctr_key;
logic                aes_ctr_key_valid;
logic                aes_ctr_key_ready;
logic [127:0]        aes_ctr_iv;
logic                aes_ctr_iv_valid;
logic [127:0]        aes_ctr_din;
logic                aes_ctr_din_valid;
logic                aes_ctr_din_ready;
logic [127:0]        aes_ctr_dout;
logic                aes_ctr_dout_valid;
logic                aes_ctr_dout_ready;

// GHASH signal
logic [127:0] ghash_h;
logic         ghash_h_valid;
logic [127:0] ghash_din;
logic         ghash_din_valid;
logic         ghash_din_ready;
logic         ghash_din_last;
logic [127:0] ghash_dout;
logic         ghash_dout_valid;


//////////////////////////////////////////////////////////////////////
// Instance
//////////////////////////////////////////////////////////////////////

aes_ctr u_aes_ctr(
    .clk,
    .rst_n,
    .key_i        (aes_ctr_key),
    .key_valid_i  (aes_ctr_key_valid),
    .key_ready_o  (aes_ctr_key_ready),
    .iv_i         (aes_ctr_iv),
    .iv_valid_i   (aes_ctr_iv_valid),
    .din_i        (aes_ctr_din),
    .din_valid_i  (aes_ctr_din_valid),
    .din_ready_o  (aes_ctr_din_ready),
    .dout_o       (aes_ctr_dout),
    .dout_valid_o (aes_ctr_dout_valid),
    .dout_ready_i (aes_ctr_dout_ready)
);

ghash u_ghash(
    .clk,
    .rst_n,
    .h_i          (ghash_h),
    .h_valid_i    (ghash_h_valid),
    .din_i        (ghash_din),
    .din_valid_i  (ghash_din_valid),
    .din_ready_o  (ghash_din_ready),
    .last_i       (ghash_din_last),
    .dout_o       (ghash_dout),
    .dout_valid_o (ghash_dout_valid)
);


//////////////////////////////////////////////////////////////////////
// Combinational Logic
//////////////////////////////////////////////////////////////////////

// FSM
always_comb begin
    case (state_reg)
        S_IDLE:
            state_next = (key_valid_i & key_ready_o) ? S_H_SETUP : S_IDLE;

        S_H_SETUP:
            state_next = S_H_CALC;

        S_H_CALC:
            state_next = (aes_ctr_din_ready) ? S_H_WAIT : S_H_CALC;

        S_H_WAIT:
            state_next = (aes_ctr_dout_valid) ? S_DATA_SETUP : S_H_WAIT;

        S_DATA_SETUP:
            state_next = (iv_cfg_done_reg) ? S_DATA_PROCESS : S_DATA_SETUP;

        S_DATA_PROCESS:
            state_next = (din_last_i & din_valid_i & din_ready_o)
                         ? S_DATA_LAST : S_DATA_PROCESS;

        S_DATA_LAST:
            state_next = (ghash_din_ready) ? S_GHASH_LEN : S_DATA_LAST;

        S_GHASH_LEN:
            state_next = S_GHASH_LEN_WAIT;

        S_GHASH_LEN_WAIT:
            state_next = (ghash_dout_valid) ? S_TAG_SETUP : S_GHASH_LEN_WAIT;

        S_TAG_SETUP:
            state_next = S_TAG_CALC;

        S_TAG_CALC:
            state_next = (aes_ctr_din_ready) ? S_DONE : S_TAG_CALC;

        S_DONE:
            state_next = S_IDLE;

        default:
            state_next = S_IDLE;
    endcase
end

// AES-CTR Control
always_comb begin
    aes_ctr_key        = 128'h0;
    aes_ctr_key_valid  = 1'b0;
    aes_ctr_iv         = 128'h0;
    aes_ctr_iv_valid   = 1'b0;
    aes_ctr_din        = 128'h0;
    aes_ctr_din_valid  = 1'b0;
    aes_ctr_dout_ready = 1'b1;

    case (state_reg)
        S_IDLE: begin
            if (key_valid_i) begin
                aes_ctr_key       = key_i[127:0];
                aes_ctr_key_valid = 1'b1;
            end
        end

        S_H_SETUP: begin
            aes_ctr_iv         = 128'h0;
            aes_ctr_iv_valid   = 1'b1;
        end

        S_H_CALC: begin
            aes_ctr_din        = 128'h0;
            aes_ctr_din_valid  = 1'b1;
        end

        S_H_WAIT: begin
            aes_ctr_dout_ready = 1'b1;
        end

        S_DATA_SETUP: begin
            aes_ctr_iv         = {iv_reg, 32'h2};
            aes_ctr_iv_valid   = iv_cfg_done_reg;
        end

        S_DATA_PROCESS: begin
            aes_ctr_din        = din_i;
            aes_ctr_din_valid  = din_valid_i;
            aes_ctr_dout_ready = ghash_din_ready;
        end

        S_TAG_SETUP: begin
            aes_ctr_iv         = {iv_reg, 32'h1};
            aes_ctr_iv_valid   = 1'b1;
        end

        S_TAG_CALC: begin
            aes_ctr_din        = ghash_result_reg;
            aes_ctr_din_valid  = 1'b1;
        end
    endcase
end

// GHASH Control
always_comb begin
    ghash_h         = 128'h0;
    ghash_h_valid   = 1'b0;
    ghash_din       = 128'h0;
    ghash_din_valid = 1'b0;
    ghash_din_last  = 1'b0;

    case (state_reg)
        S_H_WAIT: begin
            ghash_h       = aes_ctr_dout;
            ghash_h_valid = aes_ctr_dout_valid;
        end

        default: begin
            ghash_h         = 128'h0;
            ghash_h_valid   = 1'b0;
        end

        S_DATA_PROCESS, S_DATA_LAST: begin
            if (mode_i == ENCRYPT) begin
                ghash_din       = aes_ctr_dout;
                ghash_din_valid = aes_ctr_dout_valid;
                ghash_din_last  = 1'b0;

            end else begin
                ghash_din       = din_reg;
                ghash_din_valid = din_valid_reg;
                ghash_din_last  = 1'b0;
            end
        end

        S_GHASH_LEN: begin
            ghash_din       = {64'b0, block_count_reg, 7'b0};
            ghash_din_valid = 1'b1;
            ghash_din_last  = 1'b1;
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

// iv, iv_cfg_done
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        iv_reg          <= 96'h0;
        iv_cfg_done_reg <= 1'b0;
    end else begin
        if (iv_valid_i) begin
            iv_reg          <= iv_i;
            iv_cfg_done_reg <= 1'b1;
        end
    end
end

// block_count
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        block_count_reg <= 57'h0;
    end else begin
        if (state_reg == S_IDLE)
            block_count_reg <= 57'h0;

        else if (din_valid_i & din_ready_o)
            block_count_reg <= block_count_reg + 57'h1;
    end
end

// ghash_result
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ghash_result_reg <= 128'h0;
    end else begin
        if (ghash_dout_valid)
            ghash_result_reg <= ghash_dout;
    end
end

// delay din/din_valid for decryption GHASH input
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        din_reg       <= 128'h0;
        din_valid_reg <= 1'b0;
    end else if (state_reg == S_DATA_PROCESS || state_reg == S_DATA_LAST) begin
        din_reg       <= din_i;
        din_valid_reg <= (din_i == din_reg) ? 1'b0 : din_valid_i;
    end
end

//////////////////////////////////////////////////////////////////////
// Output Logic
//////////////////////////////////////////////////////////////////////

assign key_ready_o = (state_reg == S_IDLE); // only accept key in IDLE state

assign din_ready_o = (state_reg == S_DATA_PROCESS) & aes_ctr_din_ready;

// dout
assign dout_o       = aes_ctr_dout;
assign dout_valid_o = (state_reg == S_DATA_PROCESS || state_reg == S_DATA_LAST)
                      & aes_ctr_dout_valid;

// tag
assign tag_o       = (state_reg == S_DONE) ? aes_ctr_dout : 128'h0;
assign tag_valid_o = (state_reg == S_DONE);

endmodule
