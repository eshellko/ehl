// Design:           Pipeline stager with Ready-Valid handshake
// Revision:         1.0
// Date:             2018-10-01
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2018-10-01 A.Kornukhin: initial release

module ehl_rv_pipe
#(
   parameter [0:0] ENA = 1'b0,
   parameter WIDTH = 8
)
(
   input                  clk,
                          reset_n,
   input                  in_valid,
   output                 in_ready,
   output reg             out_valid,
   input                  out_ready,
   input [WIDTH-1:0]      data_in,
   output reg [WIDTH-1:0] data_out
);
   assign in_ready = !out_valid | (out_ready & out_valid); // EMPTY | READ
`ifdef ALTERA
generate
`endif
   if(ENA)
   begin : pipe_reg
      always@(posedge clk or negedge reset_n)
      if(!reset_n)
         out_valid <= 1'b0;
      else
         out_valid <= (in_ready & in_valid) | (out_valid & !out_ready);// WRITE | FULL and no READ

      always@(posedge clk)
      if(in_ready & in_valid)
         data_out <= data_in;
   end
   else
   begin : pipe_bypass
      always@*
         out_valid = in_valid;

      always@*
         data_out = data_in;
   end
`ifdef ALTERA
endgenerate
`endif
endmodule
