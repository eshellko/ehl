// Design:           Open Source Standard Cell Library for Generic Synthesis
// Revision:         1.0
// Date:             2016-12-20
// Company:          Eshell
// Designer:         A.Kornukhin (asic.eshell@gmail.com)
// Last modified by: 1.0 2016-12-20 A.Kornukhin: initial release

// TODO: add negedge clocked flops
// TODO: and primitives and specify for timing annotation

module AND2 ( input A, B, output Q);
   assign Q = A & B;
endmodule

module OR2 ( input A, B, output Q);
   assign Q = A | B;
endmodule

module XOR2 ( input A, B, output Q);
   assign Q = A ^ B;
endmodule

module MUX2 ( input S, A0, A1, output Q);
   assign Q = S ? A1 : A0;
endmodule

module BUF ( input A, output Q);
   assign Q = A;
endmodule

module INV ( input A, output Q);
   assign Q = !A;
endmodule

module TSBUF ( input A, OE, output Q);
   assign Q = OE ? A : 1'bz;
endmodule

module DLAT ( input D, CK, output reg Q);
   always@*
   if(CK)
      Q <= D;
endmodule

module DLATN ( input D, CK, output reg Q);
   always@*
   if(!CK)
      Q <= D;
endmodule

module ICG ( input  CK, EN, output Q);
   reg gate;
   always@*
   if(!CK)
      gate <= EN;
   assign Q = CK & gate;
endmodule

module DFF ( input D, CK, output reg Q);
   always@(posedge CK)
      Q <= D;
endmodule

module DFFR ( input D, CK, RN, output reg Q);
   always@(posedge CK or negedge RN)
   if(!RN)
      Q <= 1'b0;
   else
      Q <= D;
endmodule

module DFFS ( input D, CK, SN, output reg Q);
   always@(posedge CK or negedge SN)
   if(!SN)
      Q <= 1'b1;
   else
      Q <= D;
endmodule

module SDFF ( input D, CK, SE, SI, output reg Q);
   always@(posedge CK)
   if(SE)
      Q <= SI;
   else
      Q <= D;
endmodule

module SDFFR ( input D, CK, RN, SE, SI, output reg Q);
   always@(posedge CK or negedge RN)
   if(!RN)
      Q <= 1'b0;
   else if(SE)
      Q <= SI;
   else
      Q <= D;
endmodule

module SDFFS ( input D, CK, SN, SE, SI, output reg Q);
   always@(posedge CK or negedge SN)
   if(!SN)
      Q <= 1'b1;
   else if(SE)
      Q <= SI;
   else
      Q <= D;
endmodule

module TIEL ( output Q);
   assign Q = 1'b0;
endmodule

module TIEH ( output Q);
   assign Q = 1'b1;
endmodule
