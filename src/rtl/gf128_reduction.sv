/*
 * gf128_reduction.sv
 * ------------------
 * Description : GF(2^128) Reduction Module
 */

module gf128_reduction(
    input  logic         valid_i,
    input  logic [255:0] data_i,

    output logic         valid_o,
    output logic [127:0] data_o
);

logic [127:0] data_hi, data_lo;

assign data_hi = data_i[255:128];
assign data_lo = data_i[127:0];
assign valid_o = valid_i;

always_comb begin
    data_o[0]  = data_hi[0] ^ data_hi[121] ^ data_hi[126] ^ data_lo[0];
    data_o[1]  = data_hi[0] ^ data_hi[1]   ^ data_hi[121] ^ data_hi[122] ^ data_hi[126] ^ data_lo[1];
    data_o[2]  = data_hi[0] ^ data_hi[1]   ^ data_hi[2]   ^ data_hi[121] ^ data_hi[122] ^ data_hi[123] ^ data_hi[126] ^ data_lo[2];
    data_o[3]  = data_hi[1] ^ data_hi[2]   ^ data_hi[3]   ^ data_hi[122] ^ data_hi[123] ^ data_hi[124] ^ data_lo[3];
    data_o[4]  = data_hi[2] ^ data_hi[3]   ^ data_hi[4]   ^ data_hi[123] ^ data_hi[124] ^ data_hi[125] ^ data_lo[4];
    data_o[5]  = data_hi[3] ^ data_hi[4]   ^ data_hi[5]   ^ data_hi[124] ^ data_hi[125] ^ data_hi[126] ^ data_lo[5];
    data_o[6]  = data_hi[4] ^ data_hi[5]   ^ data_hi[6]   ^ data_hi[125] ^ data_hi[126] ^ data_lo[6];
    data_o[7]  = data_hi[0] ^ data_hi[5]   ^ data_hi[6]   ^ data_hi[7]   ^ data_hi[121] ^ data_lo[7];
    data_o[8]  = data_hi[1] ^ data_hi[6]   ^ data_hi[7]   ^ data_hi[8]   ^ data_hi[122] ^ data_lo[8];
    data_o[9]  = data_hi[2] ^ data_hi[7]   ^ data_hi[8]   ^ data_hi[9]   ^ data_hi[123] ^ data_lo[9];
    data_o[10] = data_hi[3] ^ data_hi[8]   ^ data_hi[9]   ^ data_hi[10]  ^ data_hi[124] ^ data_lo[10];
    data_o[11] = data_hi[4] ^ data_hi[9]   ^ data_hi[10]  ^ data_hi[11]  ^ data_hi[125] ^ data_lo[11];
    data_o[12] = data_hi[5] ^ data_hi[10]  ^ data_hi[11]  ^ data_hi[12]  ^ data_hi[126] ^ data_lo[12];

    for(int i = 13; i < 127; i = i + 1)begin
        data_o[i] = data_hi[i-7] ^ data_hi[i-2] ^ data_hi[i-1] ^ data_hi[i] ^ data_lo[i];
    end

    data_o[127] = data_hi[120] ^ data_hi[125] ^ data_hi[126] ^ data_lo[127];
end

// x^128 = x^7 + x^2 + x + 1
// x^129 = x^8 + x^3 + x^2 + x
// x^130 = x^9 + x^4 + x^3 + x^2
// x^131 = x^10 + x^5 + x^4 + x^3
// x^132 = x^11 + x^6 + x^5 + x^4
// x^133 = x^12 + x^7 + x^6 + x^5
// x^134 = x^13 + x^8 + x^7 + x^6
// ...
// x^249 = x^128 + x^123 + x^122 + x^121
//       = x^123 + x^122 + x^121 + x^7  + x^2 + x   + 1
// x^250 = x^124 + x^123 + x^122 + x^8  + x^3 + x^2 + x
// x^251 = x^125 + x^124 + x^123 + x^9  + x^4 + x^3 + x^2
// x^252 = x^126 + x^125 + x^124 + x^10 + x^5 + x^4 + x^3
// x^253 = x^127 + x^126 + x^125 + x^11 + x^6 + x^5 + x^4
// x^254 = x^128 + x^127 + x^126 + x^12 + x^7 + x^6 + x^5
//       = x^127 + x^126 + x^12  + x^7  + x^6 + x^5 + x^7 + x^2 + x + 1
//       = x^127 + x^126 + x^12  + x^6  + x^5 + x^2 + x   + 1

endmodule
