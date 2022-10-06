// Design:           GPIO Decoder
// Revision:         1.2
// Date:             2020-09-18
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2011-12-24 A.Kornukhin: initial release
//                   1.1 2019-10-08 A.Kornukhin: part of address used for decoding atomic operations
//                   1.2 2020-09-18 A.Kornukhin: bit accesses combined to allow access few bits at time

module ehl_gpio_decoder
#(
   parameter WIDTH = 32,
   GDOR_ENA = 5'b11111,
   GOER_ENA = 5'b11111,
   GAFR_ENA = 5'b11111,
   GPER_ENA = 5'b11111,
   GPTR_ENA = 5'b11111,
   GIER_ENA = 5'b11111,
   GISR_ENA = 5'b11111,
   GCMR_ENA = 5'b11111,
   GFMR_ENA = 5'b11111,
   READ_GIFR_ENA = 1,
   CLR_GIFR_ENA = 1,
   READ_GDIR_ENA = 1
)
(
   input wr, rd,
   input [5:0] addr,
   input [WIDTH-1:0]  data_in,
   output [WIDTH-1:0]
   set_gdor, set_goer, set_gafr, set_gper,
   set_gptr, set_gier, set_gisr, set_gcmr, set_gfmr,
   clr_gdor, clr_goer, clr_gafr, clr_gper,
   clr_gptr, clr_gier, clr_gisr, clr_gifr, clr_gcmr, clr_gfmr,
   inv_gdor, inv_goer, inv_gafr, inv_gper,
   inv_gptr, inv_gier, inv_gisr, inv_gcmr, inv_gfmr,
   output write_gdor, write_goer, write_gafr, write_gper,
   write_gptr, write_gier, write_gisr, write_gcmr, write_gfmr,
   read_gdor, read_goer, read_gafr, read_gper,
   read_gptr, read_gier, read_gisr, read_gifr, read_gdir, read_gcmr, read_gfmr
);
// addr(5:2)
// 0 - gdor
// 1 - goer
// 2 - gafr
// 3 - gper
// 4 - gptr
// 5 - gier
// 6 - gisr
// 7 - gifr
// 8 - gdir
// 9 - gcmr
//10 - gfmr
   assign write_gdor = GDOR_ENA[0] && addr == {4'h0,2'h0} && wr;
   assign write_goer = GOER_ENA[0] && addr == {4'h1,2'h0} && wr;
   assign write_gafr = GAFR_ENA[0] && addr == {4'h2,2'h0} && wr;
   assign write_gper = GPER_ENA[0] && addr == {4'h3,2'h0} && wr;
   assign write_gptr = GPTR_ENA[0] && addr == {4'h4,2'h0} && wr;
   assign write_gier = GIER_ENA[0] && addr == {4'h5,2'h0} && wr;
   assign write_gisr = GISR_ENA[0] && addr == {4'h6,2'h0} && wr;
   assign write_gcmr = GCMR_ENA[0] && addr == {4'h9,2'h0} && wr;
   assign write_gfmr = GCMR_ENA[0] && addr == {4'ha,2'h0} && wr;
// addr(1:0)
// 0 - write
// 1 - set
// 2 - clear
// 3 - invert
   assign set_gdor = wr && GDOR_ENA[4] && addr == {4'd0, 2'h1} ? data_in : {WIDTH{1'b0}};
   assign set_goer = wr && GOER_ENA[4] && addr == {4'd1, 2'h1} ? data_in : {WIDTH{1'b0}};
   assign set_gafr = wr && GAFR_ENA[4] && addr == {4'd2, 2'h1} ? data_in : {WIDTH{1'b0}};
   assign set_gper = wr && GPER_ENA[4] && addr == {4'd3, 2'h1} ? data_in : {WIDTH{1'b0}};
   assign set_gptr = wr && GPTR_ENA[4] && addr == {4'd4, 2'h1} ? data_in : {WIDTH{1'b0}};
   assign set_gier = wr && GIER_ENA[4] && addr == {4'd5, 2'h1} ? data_in : {WIDTH{1'b0}};
   assign set_gisr = wr && GISR_ENA[4] && addr == {4'd6, 2'h1} ? data_in : {WIDTH{1'b0}};
   assign set_gcmr = wr && GCMR_ENA[4] && addr == {4'd9, 2'h1} ? data_in : {WIDTH{1'b0}};
   assign set_gfmr = wr && GCMR_ENA[4] && addr == {4'ha, 2'h1} ? data_in : {WIDTH{1'b0}};
   assign clr_gdor = wr && GDOR_ENA[3] && addr == {4'd0, 2'h2} ? data_in : {WIDTH{1'b0}};
   assign clr_goer = wr && GOER_ENA[3] && addr == {4'd1, 2'h2} ? data_in : {WIDTH{1'b0}};
   assign clr_gafr = wr && GAFR_ENA[3] && addr == {4'd2, 2'h2} ? data_in : {WIDTH{1'b0}};
   assign clr_gper = wr && GPER_ENA[3] && addr == {4'd3, 2'h2} ? data_in : {WIDTH{1'b0}};
   assign clr_gptr = wr && GPTR_ENA[3] && addr == {4'd4, 2'h2} ? data_in : {WIDTH{1'b0}};
   assign clr_gier = wr && GIER_ENA[3] && addr == {4'd5, 2'h2} ? data_in : {WIDTH{1'b0}};
   assign clr_gisr = wr && GISR_ENA[3] && addr == {4'd6, 2'h2} ? data_in : {WIDTH{1'b0}};
   assign clr_gifr = wr && CLR_GIFR_ENA && addr == {4'd7, 2'h2} ? data_in : {WIDTH{1'b0}};
   assign clr_gcmr = wr && GCMR_ENA[3] && addr == {4'd9, 2'h2} ? data_in : {WIDTH{1'b0}};
   assign clr_gfmr = wr && GCMR_ENA[3] && addr == {4'ha, 2'h2} ? data_in : {WIDTH{1'b0}};
   assign inv_gdor = wr && GDOR_ENA[2] && addr == {4'd0, 2'h3} ? data_in : {WIDTH{1'b0}};
   assign inv_goer = wr && GOER_ENA[2] && addr == {4'd1, 2'h3} ? data_in : {WIDTH{1'b0}};
   assign inv_gafr = wr && GAFR_ENA[2] && addr == {4'd2, 2'h3} ? data_in : {WIDTH{1'b0}};
   assign inv_gper = wr && GPER_ENA[2] && addr == {4'd3, 2'h3} ? data_in : {WIDTH{1'b0}};
   assign inv_gptr = wr && GPTR_ENA[2] && addr == {4'd4, 2'h3} ? data_in : {WIDTH{1'b0}};
   assign inv_gier = wr && GIER_ENA[2] && addr == {4'd5, 2'h3} ? data_in : {WIDTH{1'b0}};
   assign inv_gisr = wr && GISR_ENA[2] && addr == {4'd6, 2'h3} ? data_in : {WIDTH{1'b0}};
   assign inv_gcmr = wr && GCMR_ENA[2] && addr == {4'd9, 2'h3} ? data_in : {WIDTH{1'b0}};
   assign inv_gfmr = wr && GCMR_ENA[2] && addr == {4'ha, 2'h3} ? data_in : {WIDTH{1'b0}};

   assign read_gdor = GDOR_ENA[1] && addr=={4'd0,2'h0} && rd;
   assign read_goer = GOER_ENA[1] && addr=={4'd1,2'h0} && rd;
   assign read_gafr = GAFR_ENA[1] && addr=={4'd2,2'h0} && rd;
   assign read_gper = GPER_ENA[1] && addr=={4'd3,2'h0} && rd;
   assign read_gptr = GPTR_ENA[1] && addr=={4'd4,2'h0} && rd;
   assign read_gier = GIER_ENA[1] && addr=={4'd5,2'h0} && rd;
   assign read_gisr = GISR_ENA[1] && addr=={4'd6,2'h0} && rd;
   assign read_gifr = READ_GIFR_ENA && addr=={4'd7,2'h0} && rd;
   assign read_gdir = READ_GDIR_ENA && addr=={4'd8,2'h0} && rd;
   assign read_gcmr = GCMR_ENA[1] && addr=={4'd9,2'h0} && rd;
   assign read_gfmr = GCMR_ENA[1] && addr=={4'ha,2'h0} && rd;

endmodule
