// Design:           Watchdog timer
// Revision:         1.0
// Date:             2022-07-11
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2022-07-11 A.Kornukhin: Initial release

module ehl_wdt
#(
   parameter WIDTH = 32 // system bus width
)
(
   input  clk,         // system and timer clock
   input  reset_n,     // system reset (except watchdog reset itself)
   input  wdt_reset_n, // watchdog reset

   output     irq,     // interrupt request
   output reg rst_req, // reset request

   input                  wr,
   input                  rd,
   input  [4:0]           addr,
   input  [WIDTH-1:0]     wdata,
   output reg [WIDTH-1:0] rdata
);
`ifndef SYNTHESIS
   initial
   begin
      if(WIDTH != 8 && WIDTH != 16 && WIDTH != 32)
      begin
         $display("   Error: '%m' incorrect value %0d for parameter WIDTH (8, 16, 32).", WIDTH);
         $finish;
      end
   end
`endif

   localparam CSR_LOAD     = 32'h0 << 2;
   localparam CSR_VAL      = 32'h1 << 2;
   localparam CSR_LOCK     = 32'h2 << 2;
   localparam CSR_IRQ_CTRL = 32'h3 << 2;
   localparam CSR_IRQ_FLAG = 32'h4 << 2;
   // Note: write strobes per byte per CSR
   wire [3:0] strb_load;
   wire strb_lock, strb_irq_ctrl, strb_irq_flag;

   reg [31:0] load;
   reg [31:0] val;
   reg        lock;
   reg        ie, re;
   reg        rst_flag, irq_flag;

   reg next_last;

   wire [4:0] addr_full = {addr[4:2], 2'h0};
   logic [3:0] wr_strb;
   always_comb
   if(WIDTH == 32)
      wr_strb = {4{wr}};
   else if(WIDTH == 16)
      wr_strb = {4{wr}} & {addr[1], addr[1], ~addr[1], ~addr[1]};
   else
      wr_strb = {4{wr}} & {addr[1:0]==2'b11, addr[1:0]==2'b10, addr[1:0]==2'b01, addr[1:0]==2'b00};

   assign strb_load     = (addr_full == CSR_LOAD     && !lock) ? wr_strb : 4'h0;
   assign strb_lock     = (addr_full == CSR_LOCK             ) ? wr_strb[0] : 1'h0;
   assign strb_irq_ctrl = (addr_full == CSR_IRQ_CTRL && !lock) ? wr_strb[0] : 1'h0;
   assign strb_irq_flag = (addr_full == CSR_IRQ_FLAG && !lock) ? wr_strb[0] : 1'h0;

   wire [1:0] csr_shift = WIDTH == 32 ? 2'd0 : WIDTH == 16 ? {addr[1], 1'b0} : addr[1:0];
   always_comb
   if(rd)
   begin
      case (addr_full)
         CSR_LOAD     : rdata = load                        >> (6'd8*csr_shift);
         CSR_VAL      : rdata = val                         >> (6'd8*csr_shift);
         CSR_LOCK     : rdata = {31'h0, lock}               >> (6'd8*csr_shift);
         CSR_IRQ_CTRL : rdata = {30'b0, re, ie}             >> (6'd8*csr_shift);
         CSR_IRQ_FLAG : rdata = {30'b0, rst_flag, irq_flag} >> (6'd8*csr_shift);
         default      : rdata = 32'h0;
      endcase
   end
   else
      rdata = {WIDTH{1'h0}};

   wire [31:0] csr_din = WIDTH==32 ? wdata :
                         WIDTH==16 ? {2{wdata}} :
                         {4{wdata}};
   wire reload = strb_load[3];
   integer i;
   always_ff @(posedge clk or negedge wdt_reset_n)
   if(!wdt_reset_n)
   begin
      load     <= 32'h0;
      lock     <= 1'h1;
      ie       <= 1'h0;
      re       <= 1'h0;
      irq_flag <= 1'h0;
   end
   else
   begin
      if(strb_lock)
         lock <= !(csr_din[7:0] == 8'hd9);

      if(strb_irq_ctrl)
         {re, ie} <= csr_din[1:0];

      if(strb_irq_flag)
         irq_flag <= csr_din[0] ? 1'b0 : irq_flag;
      if(next_last && !reload)
         irq_flag <= 1'b1;

      for(i = 0; i < 4; i = i + 1)
         if(strb_load[i]) load[i*8+:8] <= csr_din[i*8+:8];
   end

   always_ff @(posedge clk or negedge wdt_reset_n)
   if(!wdt_reset_n)
      next_last <= 1'b0;
   else
      next_last <= val == 1;

   always_ff@(posedge clk or negedge wdt_reset_n)
   if(!wdt_reset_n)
      val <= 32'h0;
   else if(reload)
      val <= (WIDTH==8) ? {csr_din[31:24], load[23:0]} :
             (WIDTH==16) ? {csr_din[31:16], load[15:0]} :
             csr_din;
   else
      val <= val ? val - 32'b1 : next_last ? load : 32'h0;

   always_ff @(posedge clk or negedge wdt_reset_n)
   if(!wdt_reset_n)
      rst_req <= 1'h0;
   else if(next_last && !reload && irq_flag && re)
      rst_req <= 1'h1;
   else
      rst_req <= 1'h0;

   always_ff @(posedge clk or negedge reset_n)
   if(!reset_n)
      rst_flag <= 1'b0;
   else if(rst_req)
      rst_flag <= 1'b1;
   else if(strb_irq_flag)
      rst_flag <= csr_din[1] ? 1'b0 : rst_flag;

   assign irq = ie & irq_flag;

endmodule
