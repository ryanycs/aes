/*
 * aes_ctr.sv
 * ----------
 * Description : AES-CTR Module
 */
`include "define.svh"

module aes_ctr(
    input  logic                clk,
    input  logic                rst_n,

    // Key
    input  logic [KEY_SIZE-1:0] key_i,
    input  logic                key_valid_i,
    output logic                key_ready_o,  // Key expansion module is ready

    // IV (Initialization Vector)
    input  logic [127:0]        iv_i,
    input  logic                iv_valid_i,

    // Data Input/Output
    input  logic [127:0]        din_i,
    input  logic                din_valid_i,
    output logic                din_ready_o,

    output logic [127:0]        dout_o,
    output logic                dout_valid_o,
    input  logic                dout_ready_i
);

//////////////////////////////////////////////////////////////////////
// Register
//////////////////////////////////////////////////////////////////////

logic [127:0] counter_reg;

logic         key_cfg_done_reg;  // Round keys is generated

logic         iv_cfg_done_reg;   // IV is set

logic [127:0] dout_reg;
logic         dout_valid_reg;

//////////////////////////////////////////////////////////////////////
// Wire
//////////////////////////////////////////////////////////////////////

// counter
logic [127:0] counter_next;

// key_expansion signal
logic         key_exp_ready;
logic         key_exp_done;
logic [127:0] round_key [Nr:0];

// AES signal
logic         aes_input_valid;
logic         aes_output_valid;
logic [127:0] aes_ciphertext;

// FIFO signal
logic         fifo_push;
logic         fifo_pop;
logic [127:0] fifo_dout;
logic         fifo_empty;
logic         fifo_full;

/* verilator lint_off UNUSED */
logic         fifo_almost_empty;
logic         fifo_almost_full;
/* verilator lint_on UNUSED */

// Flush signal
logic         flush;
assign flush = !(key_valid_i | iv_valid_i);  // Flush when new key or IV set


///////////////////////////////////////////////////////////////////////
// Instance
///////////////////////////////////////////////////////////////////////

// inc32
inc #(.s(32)) u_inc32 (
    .data_i (counter_reg),
    .data_o (counter_next)
);

key_expansion u_key_expansion(
    .clk,
    .rst_n,
    .valid_i     (key_valid_i),
    .ready_o     (key_exp_ready),
    .key_i       (key_i),
    .valid_o     (key_exp_done),
    .round_key_o (round_key)
);

// AES core
aes u_aes(
    .clk,
    .rst_n        (rst_n & flush),
    .en           (!fifo_full),       // Enable when FIFO is not full
    .valid_i      (aes_input_valid),
    .plaintext_i  (counter_reg),
    .round_key_i  (round_key),
    .valid_o      (aes_output_valid),
    .ciphertext_o (aes_ciphertext)    // Connect to FIFO data_i
);
assign aes_input_valid = key_cfg_done_reg & iv_cfg_done_reg;

// FIFO to buffer cipher(CB)
fifo #(
    .DEPTH(2)
) u_fifo (
    .clk,
    .rst_n          (rst_n & flush),
    .push_i         (fifo_push),
    .data_i         (aes_ciphertext),
    .pop_i          (fifo_pop),
    .data_o         (fifo_dout),
    .empty_o        (fifo_empty),
    .full_o         (fifo_full),
    .almost_empty_o (fifo_almost_empty),
    .almost_full_o  (fifo_almost_full)
);
assign fifo_push = aes_output_valid;
assign fifo_pop  = din_valid_i & din_ready_o;


//////////////////////////////////////////////////////////////////////
// Sequential Logic
//////////////////////////////////////////////////////////////////////

// counter
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter_reg <= 128'h0;
    end else begin
        if (iv_valid_i)
            counter_reg <= iv_i;

        else if (!fifo_full & aes_input_valid)
            counter_reg <= counter_next;
    end
end

// key_cfg_done
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        key_cfg_done_reg <= 1'b0;
    end else begin
        if (key_valid_i)
            key_cfg_done_reg <= 1'b0;

        else if (key_exp_done)
            key_cfg_done_reg <= 1'b1;
    end
end

// iv_cfg_done
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        iv_cfg_done_reg <= 1'b0;
    end else begin
        if (iv_valid_i)
            iv_cfg_done_reg <= 1'b1;
    end
end

// dout_valid
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dout_valid_reg <= 1'b0;
    end else begin
        dout_valid_reg <= fifo_pop;
    end
end

// dout
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dout_reg <= 128'h0;
    end else if (fifo_pop) begin
        dout_reg <= din_i;
    end
end

//////////////////////////////////////////////////////////////////////
// Output
//////////////////////////////////////////////////////////////////////

assign key_ready_o  = key_exp_ready;

assign din_ready_o  = !fifo_empty & dout_ready_i;

assign dout_o       = dout_reg ^ fifo_dout;
assign dout_valid_o = dout_valid_reg;

endmodule
