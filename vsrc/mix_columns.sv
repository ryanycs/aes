module mix_columns(
    input  logic         clk,
    input  logic         rst_n,
    input  logic         valid_i,
    input  logic [127:0] state_i,
    output logic         valid_o,
    output logic [127:0] state_o
);

logic [3:0] valid;

genvar i;
generate
    for (i = 0; i < 4; i = i + 1) begin
        mix_column u_mix_column(
            .clk,
            .rst_n,
            .valid_i  (valid_i),
            .column_i (state_i[32*i +: 32]),
            .valid_o  (valid[i]),
            .column_o (state_o[32*i +: 32])
        );
    end
endgenerate

assign valid_o = &valid;

endmodule

module mix_column(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        valid_i,
    input  logic [31:0] column_i,
    output logic        valid_o,
    output logic [31:0] column_o
);

// Input column bytes
logic [7:0] s0, s1, s2, s3;

// Input pipeline registers
// logic [7:0] s2_e1, s3_e1;
// logic [7:0] s3_e2;

// Output column bytes
logic [7:0] r0, r1, r2, r3;

// Output pipeline registers
// logic [7:0] r0_e1, r1_e1, r2_e1, r3_e1;
// logic [7:0] r0_e2, r1_e2, r2_e2, r3_e2;
// logic [7:0] r0_e3, r1_e3, r2_e3, r3_e3;

// Valid pipeline registers
// logic valid_e1;
// logic valid_e2;
// logic valid_e3;

assign {s0, s1, s2, s3} = column_i;

// Multiply by x (i.e., 2) in GF(2^8)
function [7:0] xtime ([7:0] n);
    if (n[7] == 1'b1)
        xtime = (n << 1) ^ 8'h1b;
    else
        xtime = n << 1;
endfunction

// Multiply by 2 in GF(2^8)
function [7:0] mul2 ([7:0] n);
    mul2 = xtime(n);
endfunction

// Multiply by 3 in GF(2^8)
function [7:0] mul3 ([7:0] n);
    mul3 = xtime(n) ^ n;
endfunction

// always_ff @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         s2_e1 <= 8'd0;
//         s3_e1 <= 8'd0;

//         s3_e2 <= 8'd0;
//     end else begin
//         s2_e1 <= s2;
//         s3_e1 <= s3;

//         s3_e2 <= s3_e1;
//     end
// end

// always_ff @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         r0_e1 <= 8'd0;
//         r1_e1 <= 8'd0;
//         r2_e1 <= 8'd0;
//         r3_e1 <= 8'd0;

//         r0_e2 <= 8'd0;
//         r1_e2 <= 8'd0;
//         r2_e2 <= 8'd0;
//         r3_e2 <= 8'd0;

//         r0_e3 <= 8'd0;
//         r1_e3 <= 8'd0;
//         r2_e3 <= 8'd0;
//         r3_e3 <= 8'd0;
//     end else begin
//         r0_e1 <= mul2(s0) ^ mul3(s1);
//         r1_e1 <=      s0  ^ mul2(s1);
//         r2_e1 <=      s0  ^      s1 ;
//         r3_e1 <= mul3(s0) ^      s1 ;

//         r0_e2 <= r0_e1 ^      s2_e1;
//         r1_e2 <= r1_e1 ^ mul3(s2_e1);
//         r2_e2 <= r2_e1 ^ mul2(s2_e1);
//         r3_e2 <= r3_e1 ^      s2_e1;

//         r0_e3 <= r0_e2 ^      s3_e2;
//         r1_e3 <= r1_e2 ^      s3_e2;
//         r2_e3 <= r2_e2 ^ mul3(s3_e2);
//         r3_e3 <= r3_e2 ^ mul2(s3_e2);
//     end
// end

// always_ff @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         valid_e1 <= 1'b0;
//         valid_e2 <= 1'b0;
//         valid_e3 <= 1'b0;
//     end else begin
//         valid_e1 <= valid_i;
//         valid_e2 <= valid_e1;
//         valid_e3 <= valid_e2;
//     end
// end

always_comb begin
    r0 = mul2(s0) ^ mul3(s1) ^ s2       ^ s3;
    r1 = s0       ^ mul2(s1) ^ mul3(s2) ^ s3;
    r2 = s0       ^ s1       ^ mul2(s2) ^ mul3(s3);
    r3 = mul3(s0) ^ s1       ^ s2       ^ mul2(s3);
    valid_o = valid_i;
end

// assign valid_o = valid_e3;
// assign {r0, r1, r2, r3} = {r0_e3, r1_e3, r2_e3, r3_e3};

assign column_o = {r0, r1, r2, r3};

endmodule
