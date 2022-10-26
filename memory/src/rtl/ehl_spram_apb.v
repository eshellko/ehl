// Design:           SPRAM with APB interface
// Revision:         1.0
// Date:             2022-10-21
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2022-10-21 A.Kornukhin initial release

module ehl_spram_apb
#(
   parameter AWIDTH = 10,
   TECHNOLOGY = 0
)
(
// AMBA APB interface
   input         pclk,
                 presetn,
   input [31:0]  paddr,
   input         pwrite,
   input         psel,
   input         penable,
   input [31:0]  pwdata,
   output        pready,
                 pslverr,
   output [31:0] prdata
);
   wire [AWIDTH-1:0] adr;
   wire wr,
   rd;
   wire [31:0] wdata;
   wire [31:0] rdata;

   ehl_apb2generic
   #(
      .DATA_WIDTH ( 32     ),
      .ADR_WIDTH  ( AWIDTH ),
      .PIPE_RESP  ( 0      ),
      .TECHNOLOGY ( 0      )
   ) apb_inst
   (
      // AMBA APB
      .pclk      ( pclk    ),
      .presetn   ( presetn ),
      .paddr     ( paddr[AWIDTH-1:0] ),
      .pwrite    ( pwrite  ),
      .psel      ( psel    ),
      .penable   ( penable ),
      .pwdata    ( pwdata  ),
      .pready    ( pready  ),
      .pslverr   ( pslverr ),
      .prdata    ( prdata  ),
      // Generic
      .adr       ( adr     ),
      .wr        ( wr      ),
      .rd        ( rd      ),
      .err       ( 1'b0    ),
      .wdata     ( wdata   ),
      .rdata     ( rdata   ),
      .ready     ( 1'b1    ),
      .test_mode ( 1'b0    ),
      .clk_gated ( pclk_g  )
   );

   ehl_spram
   #(
      .WIDTH      ( 32       ),
      .AWIDTH     ( AWIDTH-2 ),
      .TECHNOLOGY ( 0        ),
      .REG_OUT    ( 1        ),
      .LOAD_MEM   ( 1'b0     ),
      .MEM_FILE   ( 0        ),
      .REPORT     ( 0        )
   ) ram_inst
   (
      .clk     ( pclk            ),
      .reset_n ( presetn         ),
      .wr      ( wr              ),
      .oe      ( rd              ),
      .adr_wr  ( adr[AWIDTH-1:2] ),
      .adr_rd  ( adr[AWIDTH-1:2] ),
      .din     ( wdata           ),
      .dout    ( rdata           ),
      .mem_cfg ( 3'h0            )
   );

endmodule
