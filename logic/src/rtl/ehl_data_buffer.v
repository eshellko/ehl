// Design:           Data buffer with flags
// Revision:         1.2
// Date:             2020-05-04
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2017-03-15 A.Kornukhin: initial release
//                   1.1 2017-04-11 A.Kornukhin: rd-wr collision solved,
//                       full/empty logic optimized in IMPL_PTR=1
//                   1.2 2020-05-04 A.Kornukhin: flags made registered, IMPL_PTR removed
// Description:      there are two modes:
//                   MODE = 0: data written using write pointer
//                             data read using shift register
//                             thus read path has less logic than traditional FIFO
//                   MODE = 1: data written using shift register
//                             data read using read pointer
//                             thus write path has less logic than traditional FIFO

module ehl_data_buffer
#(
   parameter DATA_WIDTH = 16,
   ADDR_WIDTH = 2,
   parameter [1:0] MODE = 0 // 0-load-by-pointer-read-by-shift, 1-load-by-shift-read-by-pointer, 2-FIFO(binary), 3-FIFO(onehot)
)
(
   input wire                   clk, reset_n,
   input wire                   wr, rd,
   input wire [DATA_WIDTH-1:0]  data_in,
   output wire [DATA_WIDTH-1:0] data_out,
   output wire                  empty,
   output wire                  full
);
   localparam MAX_A = 2 ** ADDR_WIDTH;
`ifndef SYNTHESIS
// pragma coverage block = off
   always@(posedge clk)
   if(wr & !rd & full)
      $display("   Error: '%m' buffer overflow at %0t.", $time);
// pragma coverage block = on
`endif
`ifdef ALTERA
generate
`endif
   if((MODE == 2) || (MODE == 3))
   begin : fifo_impl
   // Note: external logic should defend from overflow/underflow; thus internal in FIFO defend cause extra logic
      ehl_sc_fifo
      #(
         .DATA_WIDTH ( DATA_WIDTH    ),
         .DEPTH      ( 1<<ADDR_WIDTH ),
         .RAM_ADDR   ( MODE[0]       )
      ) fifo_inst
      (
         .clk             ( clk      ),
         .a_reset_n       ( reset_n  ),
         .s_reset_n       ( 1'b1     ),
         .wr              ( wr       ),
         .rd              ( rd       ),
         .wrdata          ( data_in  ),
         .clear_underflow ( 1'b0     ),
         .clear_overflow  ( 1'b0     ),
         .rddata          ( data_out ),
         .is_empty        ( empty    ),
         .is_full         ( full     ),
         .is_almost_empty (          ),
         .is_almost_full  (          ),
         .overflow        (          ),
         .underflow       (          )
      );
   end
   else if((MODE == 0) || (MODE == 1))
   begin : shift_impl
//================================
// Pointers
//================================
      // TODO: derive 'ptr' from 'e_level'
      reg f_full;
      reg f_empty;
// Note: with next one define - initial 'empty' value allows to keep correct logic
//       while 1 bit saved from e_level
`define __no_lvl_wrap__
`ifdef __no_lvl_wrap__
      reg [ADDR_WIDTH-1:0] e_level;
`else
      reg [ADDR_WIDTH/*-1*/:0] e_level;
`endif
      always@(posedge clk or negedge reset_n)
      if(!reset_n)
      begin
         f_full  <= 1'b0;
         f_empty <= 1'b1;
`ifdef __no_lvl_wrap__
         e_level <= {ADDR_WIDTH{1'b0}};
`else
         e_level <= {1'b1, {ADDR_WIDTH{1'b0}}};
`endif
      end
      else
      begin
         if(wr & !rd)
         begin
`ifdef __no_lvl_wrap__
            f_full  <= e_level == {{ADDR_WIDTH-1{1'b0}}, 1'b1};
`else
            f_full  <= e_level == {{ADDR_WIDTH{1'b0}}, 1'b1};
`endif
            f_empty <= 1'b0;
            e_level <= e_level - 1'b1;
         end
         else if(rd & !wr)
         begin
            f_full  <= 1'b0;
`ifdef __no_lvl_wrap__
            f_empty <= e_level == {ADDR_WIDTH{1'b1}};
`else
            f_empty <= e_level == {1'b0, {ADDR_WIDTH{1'b1}}};
`endif
            e_level <= e_level + 1'b1;
         end
      end
`undef __no_lvl_wrap__

      assign empty = f_empty;
      assign full = f_full;

      integer i, j;
      reg [ADDR_WIDTH-1:0] ptr;
      reg [DATA_WIDTH:0] data_buffer [MAX_A-1:0]; // msb is busy flag

      always@(posedge clk or negedge reset_n)
      if(!reset_n)
         ptr <= {ADDR_WIDTH{MODE[0]}};
      else
      begin
         if(wr & !rd)
            ptr <= ptr + 1'b1;
         if(rd & !wr)
            ptr <= ptr - 1'b1;
      end
//================================
// Buffer
//================================
      if(MODE == 0)
      begin : wr_ptr
         always@(posedge clk or negedge reset_n)
         if(!reset_n)
            for(i=0; i<MAX_A; i=i+1)
               data_buffer[i][DATA_WIDTH] <= 1'b0;
         else
         begin
            if(rd)
            begin
               for(i=0;i<MAX_A-1;i=i+1)
                  data_buffer[i][DATA_WIDTH]<=data_buffer[i+1][DATA_WIDTH];
               data_buffer[MAX_A-1][DATA_WIDTH]<=1'b0;
            end
            if(wr)
               data_buffer[ptr-rd][DATA_WIDTH]<=1'b1;
         end

         always@(posedge clk)
         begin
            if(rd)
               for(j=0;j<MAX_A-1;j=j+1)
                  data_buffer[j][DATA_WIDTH-1:0]<=data_buffer[j+1][DATA_WIDTH-1:0];
            if(wr)
               data_buffer[ptr-rd][DATA_WIDTH-1:0]<=data_in;
         end
   
         assign data_out = data_buffer[0][DATA_WIDTH-1:0];
      end

      else if(MODE == 1)
      begin : rd_ptr
         always@(posedge clk or negedge reset_n)
         if(!reset_n)
            for(i=0; i<MAX_A; i=i+1)
               data_buffer[i][DATA_WIDTH]<=1'b0;
         else
         begin
            if(wr)
            begin
               data_buffer[0][DATA_WIDTH]<=1'b1; // Q: if write always (except msb), but increment pointer on 'wr' - thus less logic on data path - but need additional cell to keep data when buffer full...
               for(i=1;i<MAX_A;i=i+1)
                  data_buffer[i][DATA_WIDTH]<=data_buffer[i-1][DATA_WIDTH];
               if(rd) // Note: do not propagate last valid bit up to chain
                  for(i=0;i<MAX_A;i=i+1)
                     if(i == ptr+1'b1)
                        data_buffer[i][DATA_WIDTH]<=1'b0;
            end
            if(rd)
               if(!wr)
                  data_buffer[ptr][DATA_WIDTH]<=1'b0;
         end

         always@(posedge clk)
         if(wr)
         begin
            data_buffer[0][DATA_WIDTH-1:0]<=data_in;
            for(j=1;j<MAX_A;j=j+1)
               data_buffer[j][DATA_WIDTH-1:0]<=data_buffer[j-1][DATA_WIDTH-1:0];
         end
   
         assign data_out = data_buffer[ptr][DATA_WIDTH-1:0];
      end
   end
`ifdef ALTERA
endgenerate
`endif
endmodule
