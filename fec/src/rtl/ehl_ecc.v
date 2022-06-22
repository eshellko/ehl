// Design:           Error Correction Code
// Revision:         1.7
// Date:             2021-11-11
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2014-10-14 A.Kornukhin: initial release
//                   1.1 2015-12-23 A.Kornukhin: multiple drivers on codeword[64,32,16] resolved
//                   1.2 2016-02-23 A.Kornukhin: checkbits[7:1] are now part of parity to cover checkbits errors in the same way as data errors
//                   1.3 2016-06-19 A.Kornukhin: renamed to 'ehl_ecc'
//                   1.4 2016-12-06 A.Kornukhin: size of constant added (integer->72)
//                       fixed bug in decoding single_error data
//                   1.5 2019-08-16 A.Kornukhin: se_pat* output added to log single error position
//                   1.6 2020-06-16 A.Kornukhin: signals with 'error' substituted with 'err'
//                   1.7 2021-11-11 A.Kornukhin: SEC configuration added through 'SECDED' parameter
// Description:      Module works with 8, 16, 32, or 64 bit data,
//                   generates 5, 6, 7, 8 control bits respectively,
//                   It corrects single error, and reports double errors;
//                   higher number of errors may be treated incorrectly as single errors
// Reference:        Freescale AN3532 "Error Correction and Error Handling
//                   on PowerQUICC III Processors". Section 2.2
// Notes:            Synopsys Error Correction Code (ECC)
//                   Cadence Error Checking and Correction (ECC)
//                   Gaisler Error Detection and Correction (EDAC)
//                   Freescale Single Error Correction Double Error Detection (SECDED)

module ehl_ecc
#(
   parameter WIDTH = 8,
   SECDED = 1           // 1 - SECDED, 0 - SEC (cbout[0], a.k.a. parity is not used)
)
(
   input gen,                               // mode: 1-generator
   input chk,                               // mode: 1-checker (should be: chk & gen == 0)
   input [WIDTH-1:0] din,                   // input data
   input [1+$clog2(WIDTH):0] cbin,          // input check bits
   output [WIDTH-1:0] dout,                 // output (corrected) data
   output [1+$clog2(WIDTH):0] cbout,        // generated check bits
   output [WIDTH-1:0] se_pat_dout,          // pattern of corrected data (for single errors)
   output [1+$clog2(WIDTH):0] se_pat_cbout, // pattern of corrected check bits (for single errors)
   output single_err,                       // asserted when single error detected and corrected
   double_err,                              // asserted when double error detected
   cb_err                                   // asserted if single_error detected and error in cbits
);
   localparam CWIDTH = $clog2(WIDTH) + 1;
// Note: masks for data to create XOR bits. All columns should have unique values without running-1(checkbits) and all-zero(parity)
// Note: syndrome will have value of column in MASK_i table... i.e. 3 for din[0], or 1 for cb[1]
   localparam [63:0] MASK_1 = 64'b1010_1011_0101_0101_0101_0101_0101_0101_0101_0110_1010_1010_1010_1101_0101_1011;
   localparam [63:0] MASK_2 = 64'b1100_1101_1001_1001_1001_1001_1001_1001_1001_1011_0011_0011_0011_0110_0110_1101;
   localparam [63:0] MASK_3 = 64'b1111_0001_1110_0001_1110_0001_1110_0001_1110_0011_1100_0011_1100_0111_1000_1110;
   localparam [63:0] MASK_4 = 64'b0000_0001_1111_1110_0000_0001_1111_1110_0000_0011_1111_1100_0000_0111_1111_0000;
   localparam [63:0] MASK_5 = 64'b0000_0001_1111_1111_1111_1110_0000_0000_0000_0011_1111_1111_1111_1000_0000_0000;
   localparam [63:0] MASK_6 = 64'b0000_0001_1111_1111_1111_1111_1111_1111_1111_1100_0000_0000_0000_0000_0000_0000;
   localparam [63:0] MASK_7 = 64'b1111_1110_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;

// Note: calculate checkbits ... if WIDTH smaller extended 'din' will result 0
   wire [7:0] checkbits;
   assign checkbits[0] = SECDED ? (^din ^ ^checkbits[7:1]) : 1'b0;
   assign checkbits[1] = ^(din&MASK_1);
   assign checkbits[2] = ^(din&MASK_2);
   assign checkbits[3] = ^(din&MASK_3);
   assign checkbits[4] = ^(din&MASK_4);
   assign checkbits[5] = ^(din&MASK_5);
   assign checkbits[6] = ^(din&MASK_6);
   assign checkbits[7] = ^(din&MASK_7);

   wire [CWIDTH:0] syndrome;
   assign syndrome[0] = SECDED ? (^din ^ ^cbin) : 1'b0;
   assign syndrome[CWIDTH:1] = checkbits[CWIDTH:1] ^ cbin[CWIDTH:1];

// Note: error detection
   assign single_err = SECDED ? (chk & syndrome[0]) : chk ? (|(syndrome[CWIDTH:1])) : 1'b0; // odd unmber of errors
   assign double_err = SECDED ? (chk & ~syndrome[0] & |syndrome[CWIDTH:1]) : 1'b0;
   assign cb_err = single_err & (syndrome[CWIDTH:1]==0 || syndrome[CWIDTH:1]==1 || syndrome[CWIDTH:1]==2 || syndrome[CWIDTH:1]==4 || syndrome[CWIDTH:1]==8 || syndrome[CWIDTH:1]==16 || syndrome[CWIDTH:1]==32 || syndrome[CWIDTH:1]==64);
 
// Note: mask uses indexes from 0 up to 71 in case of 64-bit data
//       where indexes 0,1,2,4,8,16,32,64 reserved for checkbits
//       thus to get valid word, this positions should be moved
   wire [71:0] mask = 72'd1 << syndrome[CWIDTH:1];

   wire [WIDTH-1:0] mask_data = {mask[71:65],mask[63:33],mask[31:17],mask[15:9],mask[7:5],mask[3]};
   wire [CWIDTH:0] mask_cb = {mask[64],mask[32],mask[16],mask[8],mask[4],mask[2:1], SECDED ? mask[0] : 1'b0};

   wire [WIDTH-1:0] data_fixed = mask_data ^ din;
   wire [CWIDTH:0]  cb_fixed   = mask_cb   ^ checkbits;

   assign dout = single_err ? data_fixed : din;
   // Note: feed-through pass from cbin[0] in SEC mode optimized away externally
   assign cbout = gen ? checkbits[CWIDTH:0] : single_err ? cb_fixed : cbin;

   assign se_pat_dout  = single_err ? mask_data : {WIDTH{1'b0}};
   assign se_pat_cbout = single_err ? mask_cb   : {CWIDTH+1{1'b0}};
`ifndef SYNTHESIS
   initial
      if(WIDTH !== 8 && WIDTH !== 16 && WIDTH !== 32 && WIDTH !== 64)
      begin
         $display("   Error: 'sw_ecc(%m)' invalid value %0d for parameter 'WIDTH' (8, 16, 32, or 64).", WIDTH);
         $finish;
      end
`endif

endmodule
