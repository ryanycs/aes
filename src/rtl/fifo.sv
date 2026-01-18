/*
 * fifo.sv
 * -------
 * Description : Synchronous FIFO Module
 */

module fifo #(
    parameter DATA_WIDTH = 128,
    parameter DEPTH = 32,
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    input  logic                  clk,
    input  logic                  rst_n,

    input  logic                  push_i,
    input  logic [DATA_WIDTH-1:0] data_i,

    input  logic                  pop_i,
    output logic [DATA_WIDTH-1:0] data_o,

    output logic                  empty_o,
    output logic                  full_o,
    output logic                  almost_empty_o,
    output logic                  almost_full_o
);

////////////////////////////////////////////////////////////////////////////////
// Register
////////////////////////////////////////////////////////////////////////////////

logic [ADDR_WIDTH-1:0] front, rear;
logic [DATA_WIDTH-1:0] queue [DEPTH-1:0];
logic [ADDR_WIDTH:0]   count;
logic [DATA_WIDTH-1:0] data_reg;


////////////////////////////////////////////////////////////////////////////////
// Wire
////////////////////////////////////////////////////////////////////////////////

logic is_empty;
logic is_full;
assign is_full  = (count == DEPTH);
assign is_empty = (count == 0);


////////////////////////////////////////////////////////////////////////////////
// Sequential Logic
////////////////////////////////////////////////////////////////////////////////

// push data
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (int i = 0; i < DEPTH; i = i + 1) begin
            queue[i] <= {DATA_WIDTH{1'b0}};
        end
    end else begin
        if (push_i & ~is_full)
            queue[rear] <= data_i;
    end
end

// front
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        front <= {ADDR_WIDTH{1'b0}};
    end else begin
        if (pop_i & ~is_empty)
            front <= front + 1;
    end
end

// rear
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rear <= {ADDR_WIDTH{1'b0}};
    end else begin
        if (push_i & ~is_full)
            rear <= rear + 1;
    end
end

// count
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count <= {(ADDR_WIDTH+1){1'b0}};
    end else begin
        case ({push_i & ~is_full, pop_i & ~is_empty})
            2'b10: count <= count + 1;
            2'b01: count <= count - 1;
            default: count <= count;
        endcase
    end
end

// pop data
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_reg <= {DATA_WIDTH{1'b0}};
    end else begin
        data_reg <= (pop_i & ~is_empty) ? queue[front] : {DATA_WIDTH{1'b0}};
    end
end


////////////////////////////////////////////////////////////////////////////////
// Output
////////////////////////////////////////////////////////////////////////////////

assign data_o         = data_reg;
assign full_o         = is_full;
assign empty_o        = is_empty;
assign almost_empty_o = (count <= 1);
assign almost_full_o  = (count >= DEPTH - 2);

endmodule
