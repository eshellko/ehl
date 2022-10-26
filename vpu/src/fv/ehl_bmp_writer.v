// Q: probably convert to task to allow multiple calls

module ehl_bmp_writer
(
   input [31*8-1:0] file_name,
   input [15:0] x, y,
   input clk,
   input valid,
   input hsync,
   input [7:0] r, g, b,
   input allow_finish,
   output reg done
);
   integer pix_count;
   integer line_pix_count;
integer dbg_left;
   integer filew;
   initial
   begin
      done = 1'b0;
   // Note: IUS fails to provide file name to this module if no delay provided - delay introduced
      #1;

      pix_count = 0;
      line_pix_count = 0;
      if(x % 4)
      begin
// TODO: x must be aligned to 4 so far... add support for padding according to BMP spec
         $display("   Internal error: line length %0d should be aligned to 4.", x);
         $finish;
      end
      filew = $fopen(file_name, "wb");
      if(filew == -1 || filew == 0)
      begin
         $display("   Error: failed to open output BMP file '%s'.", file_name);
         $finish;
      end
      $fwrite(filew, "%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c", 8'h42, 8'h4d, 8'h36, 8'hb8, 8'h0b, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h36, 8'h00, 8'h00, 8'h00, 8'h28, 8'h00, 8'h00, 8'h00, x[7:0], x[15:8], 8'h00, 8'h00, y[7:0], y[15:8], 8'h00, 8'h00, 8'h01, 8'h00, 8'h18, 8'h00, 8'h00, 8'h00);
      $fwrite(filew, "%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c", 8'h00, 8'h00, 8'h00, 8'hb8, 8'h0b, 8'h00, 8'hc3, 8'h0e, 8'h00, 8'h00, 8'hc3, 8'h0e, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00);
      pix_count = x * y;
dbg_left = pix_count;
      @(negedge clk); // to avoid x-transition to dump first pixel
      repeat(pix_count)
      begin
         while(!valid) @(posedge clk);
         // Note: BMP writes BLUE to the lowest addrfess, followed by GREEN, followed by RED
         $fwrite(filew, "%c%c%c", b, g, r);
//$display("%0t: write pixel: %x%x%x", $time, r, g, b);
dbg_left = dbg_left - 1;
         line_pix_count = line_pix_count + 1;
         if(line_pix_count == x)
            line_pix_count = 0;
         @(posedge clk);
      end
      $fclose(filew);
      done = 1'b1;
      if(allow_finish == 1'b1)
      begin
         $display("   Info: file '%s' written - function closed.", file_name);
         $finish;
      end
   end

endmodule
