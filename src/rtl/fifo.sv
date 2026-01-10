/*
 * fifo.sv
 * -------
 * Description : Synchronous FIFO Module
 */

module fifo(
    input  logic         clk,
    input  logic         rst_n,

    input  logic         push_i,
    input  logic [127:0] data_i,

    input  logic         pop_i,
    output logic [127:0] data_o,

    output logic         empty_o,
    output logic         full_o
);

////////////////////////////////////////////////////////////////////////////////
// Register
////////////////////////////////////////////////////////////////////////////////

logic [4:0]   front, rear;
logic [127:0] queue [0:31];
logic [5:0]   count;
logic [127:0] data_reg;


////////////////////////////////////////////////////////////////////////////////
// Wire
////////////////////////////////////////////////////////////////////////////////

logic is_empty;
logic is_full;
assign is_full  = (count == 6'd32);
assign is_empty = (count == 6'd0);


////////////////////////////////////////////////////////////////////////////////
// Sequential Logic
////////////////////////////////////////////////////////////////////////////////

// push data
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (int i = 0; i < 32; i = i + 1) begin
            queue[i] <= 128'd0;
        end
    end else begin
        if (push_i & ~is_full)
            queue[rear] <= data_i;
    end
end

// front
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        front <= 5'd0;
    end else begin
        if (pop_i & ~is_empty)
            front <= front + 5'd1;
    end
end

// rear
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rear <= 5'd0;
    end else begin
        if (push_i & ~is_full)
            rear <= rear + 5'd1;
    end
end

// count
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count <= 6'd0;
    end else begin
        case ({push_i & ~is_full, pop_i & ~is_empty})
            2'b10: count <= count + 6'd1;
            2'b01: count <= count - 6'd1;
            default: count <= count;
        endcase
    end
end

// pop data
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_reg <= 128'd0;
    end else begin
        data_reg <= (pop_i & ~is_empty) ? queue[front] : 128'd0;
    end
end


////////////////////////////////////////////////////////////////////////////////
// Output
////////////////////////////////////////////////////////////////////////////////

assign data_o  = data_reg;
assign full_o  = is_full;
assign empty_o = is_empty;

endmodule
