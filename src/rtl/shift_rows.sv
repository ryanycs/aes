/*
 * shift_rows.sv
 * -------------
 */

module shift_rows(
    input  logic         valid_i,
    input  logic [127:0] state_i,
    output logic         valid_o,
    output logic [127:0] state_o
);

// Row 0
assign state_o[127:120] = state_i[127:120];
assign state_o[95:88]   = state_i[95:88];
assign state_o[63:56]   = state_i[63:56];
assign state_o[31:24]   = state_i[31:24];

// Row 1
assign state_o[119:112] = state_i[87:80];
assign state_o[87:80]   = state_i[55:48];
assign state_o[55:48]   = state_i[23:16];
assign state_o[23:16]   = state_i[119:112];

// Row 2
assign state_o[111:104] = state_i[47:40];
assign state_o[79:72]   = state_i[15:8];
assign state_o[47:40]   = state_i[111:104];
assign state_o[15:8]    = state_i[79:72];

// Row 3
assign state_o[103:96]  = state_i[7:0];
assign state_o[71:64]   = state_i[103:96];
assign state_o[39:32]   = state_i[71:64];
assign state_o[7:0]     = state_i[39:32];

assign valid_o = valid_i;

endmodule
