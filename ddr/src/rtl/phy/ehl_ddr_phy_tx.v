// Design:           DDR2 PHY transmit FIFO and controller
// Revision:         1.2
// Date:             2017-11-08
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2016-12-02 A.Kornukhin: initial release
//                   1.1 2017-02-06 A.Kornukhin: rewritten to avoid timing critical
//                       paths between clk0 and clk2x posedge->negedge
//                   1.2 2017-11-08 A.Kornukhin: reset added to flops (dqs_oe, fifo_not_empty_2x)
//                       to avoid x-pessimism during backend simulation

module ehl_ddr_phy_tx
(
   input wire clk_0,
   reset_n,
   clk_2x,
   write_ena,
   wr_1tck_preamble,
   ddr4_mode,
   ddr2_mode,
   input wire [15:0] data_in,
   input wire [1:0] data_mask,
   output reg [7:0] dq,
   output reg dm,
   output reg dqs, dqs_n,
   output reg dqs_oe,
   output reg dq_oe
);
   reg ddr4_write_ena;
   always@(posedge clk_0 or negedge reset_n)
   if(!reset_n)
      ddr4_write_ena <= 1'b0;
   else
      ddr4_write_ena <= write_ena;

   wire wr_ena = (ddr4_mode | ddr2_mode) ? ddr4_write_ena : write_ena;

   reg [8:0] mem0, mem1;
   reg rptr;
// write part
   reg [8:0] ddr4_mem0, ddr4_mem1;
   always@(posedge clk_0)
   begin
      ddr4_mem0 <= {data_mask[0],data_in[7:0]};
      ddr4_mem1 <= {data_mask[1],data_in[15:8]};
   end

   always@(posedge clk_0)
   begin
      mem0 <= ddr4_mode ? ddr4_mem0 : {data_mask[0],data_in[7:0]};
      mem1 <= ddr4_mode ? ddr4_mem1 : {data_mask[1],data_in[15:8]};
   end
// read part
   reg fifo_not_empty_reg;
   reg fifo_not_empty_reg_delay_neg;
   reg fifo_not_empty_reg_delay_pos;
   always@(posedge clk_2x or negedge reset_n)
   if(!reset_n)
   begin
      fifo_not_empty_reg <= 1'b0;
      fifo_not_empty_reg_delay_pos <= 1'b0;
   end
   else
   begin
      fifo_not_empty_reg <= wr_ena;
      fifo_not_empty_reg_delay_pos <= fifo_not_empty_reg;
   end

   always@(negedge clk_2x or negedge reset_n)
   if(!reset_n)
      fifo_not_empty_reg_delay_neg <= 1'b0;
   else
      fifo_not_empty_reg_delay_neg <= fifo_not_empty_reg;

   reg fifo_not_empty_2x;
   always@(negedge clk_2x or negedge reset_n)
   if(!reset_n)
      fifo_not_empty_2x <= 1'b0;
   else
      fifo_not_empty_2x <= fifo_not_empty_reg_delay_neg;

   always@(posedge clk_2x or negedge reset_n)
   if(!reset_n)
      rptr <= 1'b0;
   else if(fifo_not_empty_reg_delay_pos)
      rptr <= ~rptr;

   always@(posedge clk_2x or negedge reset_n)
   if(!reset_n) // Note: data output cleared to avoid unknown values even they are not used
   begin
      dq    <= 8'h00;
      // Note: upon reset 'dm' and 'dq_oe' will be written with constants, as 'fifo_not_empty_reg_delay_pos' will be cleared
      dm    <= 1'bx; // 1'b1
      dq_oe <= 1'bx; // 1'b0
   end
   // Implmentation note: 'fifo_not_empty_reg_delay_pos' has high fanout that is hard to meet at DDR2-800 speed rates... probably register replication required
   //                     holds are fixed, but then setup can't be fixed due to high variation between corners
   //                     also DQ registers are located near to their respective IO cells, and delay should be fixed by buffer tree to them from single register source
   else if(fifo_not_empty_reg_delay_pos)
   begin
      dq    <= rptr ? mem1[7:0] : mem0[7:0];
      dm    <= rptr ? mem1[8]   : mem0[8];
      dq_oe <= 1'b1;
   end
   else
   begin
      dq    <= dq;
      dm    <= 1'b1;
      dq_oe <= 1'b0;
   end
// TODO: program 1tCK and 2tCK preamble with CSR
// TODO: ddr4 requires 1 cycle preamble, and 2 cycles preamble (DDR2 only 0.35)... thus preamble MUST be generated internally, and wrdata en provided as before (or wrlat reduced)
// TODO: need to program preamble type, or set it statically...
   always@(negedge clk_2x or negedge reset_n)
   if(!reset_n)
      dqs_oe <= 1'b0;
   else
      dqs_oe <= fifo_not_empty_reg_delay_neg | fifo_not_empty_2x | (wr_1tck_preamble & fifo_not_empty_reg);

// Implementation notes:
//    be sure that this registers preserved for symmetry, as they can be merged during synthesis with inverter used to implement complementary signal
//    in case of flop presence with Q and QN, where flop outputs has same driving capability, such flop can be used as single driver
   always@(negedge clk_2x or negedge reset_n)
   if(!reset_n)
   begin
      dqs   <= 1'b0;
      dqs_n <= 1'b1;
   // TODO: check if invertion can be avoided, and reset value is DC, as dqs_oe hidden
//      dqs   <= 1'b0/*ddr4*/ ^ 1/**/;
//      dqs_n <= 1'b1/*ddr4*/ ^ 1/**/;
   end
   else if(fifo_not_empty_2x | (wr_1tck_preamble & fifo_not_empty_reg_delay_neg))
   begin
      dqs   <= ~dqs;
      dqs_n <= ~dqs_n;
   end
   else
   begin
      dqs   <= wr_1tck_preamble ? 1'b1 : dqs;
      dqs_n <= wr_1tck_preamble ? 1'b0 : dqs_n;
   end

endmodule

