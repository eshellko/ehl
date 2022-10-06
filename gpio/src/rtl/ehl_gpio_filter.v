// Design:           GPIO FIlter
// Revision:         1.0
// Date:             2020-09-18
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2020-09-18 A.Kornukhin: initial release

module ehl_gpio_filter
#(
   parameter WIDTH = 32,
   CDC_TECHNOLOGY = 0,
   META_ENA = 32'hFFFFFFFF
)
(
   input                  clk,
                          reset_n,
   input [WIDTH-1:0]      gfmr,     // 0 - bypass, 1 - three consecutive cycles in a row
//    input presc_mode, // 0 - bypass, 1 - every other cycle
   input [WIDTH-1:0]      data_in,
   output reg [WIDTH-1:0] data_out
);
   wire [WIDTH-1:0] dsync;
   genvar nbit;
`ifdef ALTERA
   generate
`endif
   for(nbit=0; nbit<WIDTH; nbit=nbit+1)
   begin : cdc_gen
      localparam [1:0] LOCAL_SYNC_STAGE = META_ENA[nbit] ? 2'd3 : 2'd0;
      ehl_cdc
      #(
         .SYNC_STAGE ( LOCAL_SYNC_STAGE ),
         .TECHNOLOGY ( CDC_TECHNOLOGY   ),
         .WIDTH      ( 1                ),
         .REPORT     ( 1'b1             )
      ) sync
      (
         .clk     ( clk           ),
         .reset_n ( reset_n       ),
         .din     ( data_in[nbit] ),
         .dout    ( dsync[nbit]   )
      );
   end
`ifdef ALTERA
   endgenerate
`endif


//    reg flip;
//    always@(posedge clk or negedge reset_n)
//    if(!reset_n)
//       flip <= 1'b0;
//    else if(presc_mode)
//       flip <= ~flip;
//    else
//       flip <= 1'b0;

   integer i;
   reg [WIDTH-1:0] last;
   reg [WIDTH-1:0] filter [1:0];
   always@(posedge clk or negedge reset_n)
   if(!reset_n)
   begin
      last <= {WIDTH{1'b0}};
      filter[0] <= {WIDTH{1'b0}};
      filter[1] <= {WIDTH{1'b0}};
   end
   else // if(!flip)
   begin
      filter[0] <= dsync;
      filter[1] <= filter[0];
      for(i=0; i<WIDTH; i=i+1)
      begin
         if(filter[0][i] & filter[1][i] & dsync[i])
            last[i] <= 1'b1;
         if(!filter[0][i] & !filter[1][i] & !dsync[i])
            last[i] <= 1'b0;
      end
   end

   integer j;
   always@*
   for(j=0; j<WIDTH; j=j+1)
      data_out[j] = gfmr[j] ? last[j] : dsync[j];

endmodule
