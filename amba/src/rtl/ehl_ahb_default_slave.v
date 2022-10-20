module ehl_ahb_default_slave
(
// AHB
// haddr, hsize... hburst, hprot, hwrite, hwdata
   input hclk, hresetn,
   input [1:0] htrans,
   input hsel,
   input hready_in,
   output reg        hready,
   output reg [1:0]  hresp,
   output reg [31:0] hrdata,
// configuration
   input [7:0] resp_delay,
   input resp_val
);
   reg [7:0] wait_cnt;
   reg [1:0] state;
   localparam [1:0] ST_IDLE = 2'h0;
   localparam [1:0] ST_ERR1 = 2'h1;
   localparam [1:0] ST_ERR2 = 2'h2;

   always@(posedge hclk or negedge hresetn)
   if(!hresetn)
   begin
      hready <= 1'b1;
      hresp  <= 2'h0;
      hrdata <= 32'hDE000000;
      wait_cnt <= 8'h0;
      state <= ST_IDLE;
   end
   else
   begin
      if(hready_in & hsel & htrans != 2'h0)
      begin
         // wait cycles
         if(resp_delay)
         begin
            // ERROR response
            if(resp_val)
            begin
               hready <= 1'b0;
               wait_cnt <= resp_delay;
            end
            // OKAY
            else
            begin
               hready <= 1'b0;
               wait_cnt <= resp_delay;
            end
         end
         // immediate response
         else
         begin
            // ERROR response
            if(resp_val)
            begin
               state <= ST_ERR1;
               hready <= 1'b0;
               hresp  <= 2'h1;
               hrdata <= 32'hDE00EE00;
            end
            // OKAY
            else
            begin
               state <= ST_IDLE;
               hready <= 1'b1;
               hresp  <= 2'h0;
               hrdata <= 32'hDE000001;
            end
         end
      end
      else if(wait_cnt)
      begin
         wait_cnt <= wait_cnt - 1'b1;
         if(wait_cnt == 1)
         begin
            // ERROR response
            if(resp_val)
            begin
               state <= ST_ERR1;
               hready <= 1'b0;
               hresp  <= 2'h1;
               hrdata <= 32'h0;
            end
            // OKAY
            else
            begin
               state <= ST_IDLE;
               hready <= 1'b1;
               hresp  <= 2'h0;
               hrdata <= 32'hDE000002;
            end
         end
      end
      else if(state == ST_ERR1)
      begin
         state <= ST_ERR2;
         hready <= 1'b1;
         hresp  <= 2'h1;
         hrdata <= 32'hDE00EE00;
      end
      else if(state == ST_ERR2)
      begin
         state <= ST_IDLE;
         hready <= 1'b1;
         hresp  <= 2'h0; // TODO: possible overlap with next transaction
         hrdata <= 32'hDE000003;
      end
   end

endmodule
