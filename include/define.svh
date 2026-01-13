`ifndef DEFINE_SVH
`define DEFINE_SVH

`ifdef AES192
    parameter KEY_SIZE = 192;
    parameter EXP_PER_CYCLE = 6;
    parameter Nk = 6;
    parameter Nb = 4;
    parameter Nr = 12;
`elsif AES256
    parameter KEY_SIZE = 256;
    parameter EXP_PER_CYCLE = 4;
    parameter Nk = 8;
    parameter Nb = 4;
    parameter Nr = 14;
`else
    parameter KEY_SIZE = 128;
    parameter EXP_PER_CYCLE = 4;
    parameter Nk = 4;
    parameter Nb = 4;
    parameter Nr = 10;
`endif

`endif // DEFINE_SVH
