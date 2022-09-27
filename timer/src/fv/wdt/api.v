task API_WDT_START(input [31:0] value, input lock);
begin
   if(WIDTH == 8)
   begin
      if(lock) WRITE_REG(`LOCK8(0), 8'hd9);
      WRITE_REG(`LOAD8(0), value[7:0]);
      WRITE_REG(`LOAD8(1), value[15:8]);
      WRITE_REG(`LOAD8(2), value[23:16]);
      WRITE_REG(`LOAD8(3), value[31:24]);
      if(lock) WRITE_REG(`LOCK8(0), 8'h0);
   end
   else if(WIDTH == 16)
   begin
      if(lock) WRITE_REG(`LOCK16(0), 16'hd9);
      WRITE_REG(`LOAD16(0), value[15:0]);
      WRITE_REG(`LOAD16(1), value[31:16]);
      if(lock) WRITE_REG(`LOCK16(0), 16'h0);
   end
   else if(WIDTH == 32)
   begin
      if(lock) WRITE_REG(`LOCK32, 32'hd9);
      WRITE_REG(`LOAD32, value[31:0]);
      if(lock) WRITE_REG(`LOCK32, 32'h0);
   end
end
endtask

task API_WDT_STOP(input lock);
begin
   if(WIDTH == 8)
   begin
      if(lock) WRITE_REG(`LOCK8(0), 8'hd9);
      WRITE_REG(`LOAD8(0), 8'h0);
      WRITE_REG(`LOAD8(1), 8'h0);
      WRITE_REG(`LOAD8(2), 8'h0);
      WRITE_REG(`LOAD8(3), 8'h0);
      if(lock) WRITE_REG(`LOCK8(0), 8'h0);
   end
   else if(WIDTH == 16)
   begin
      if(lock) WRITE_REG(`LOCK16(0), 16'hd9);
      WRITE_REG(`LOAD16(0), 16'h0);
      WRITE_REG(`LOAD16(1), 16'h0);
      if(lock) WRITE_REG(`LOCK16(0), 16'h0);
   end
   else if(WIDTH == 32)
   begin
      if(lock) WRITE_REG(`LOCK32, 32'hd9);
      WRITE_REG(`LOAD32, 32'h0);
      if(lock) WRITE_REG(`LOCK32, 32'h0);
   end
end
endtask

task API_WDT_GET_TIMEOUT; // return value 'rv'
begin
   if(WIDTH == 8) begin READ_REG(`LOAD8(0)); READ_REG(`LOAD8(1)); READ_REG(`LOAD8(2)); READ_REG(`LOAD8(3)); end
   if(WIDTH == 16) begin READ_REG(`LOAD16(0)); READ_REG(`LOAD16(1)); end
   if(WIDTH == 32) READ_REG(`LOAD32);
end
endtask

task API_WDT_GET_INTERVAL; // return value 'rv'
begin
   if(WIDTH == 8) begin READ_REG(`VAL8(0)); READ_REG(`VAL8(1)); READ_REG(`VAL8(2)); READ_REG(`VAL8(3)); end
   if(WIDTH == 16) begin READ_REG(`VAL16(0)); READ_REG(`VAL16(1)); end
   if(WIDTH == 32) READ_REG(`VAL32);
end
endtask

task API_WDT_ACTIVE;
begin
   API_WDT_GET_INTERVAL;
   if(rv)
      rv = 1;
   else
      rv = 0;
end
endtask

task API_WDT_DISABLE_IRQ(input lock);
begin
   if(WIDTH == 8)
   begin
      if(lock) WRITE_REG(`LOCK8(0), 8'hd9);
      WRITE_REG(`IRQ_CTRL8(0), 8'h0);
      if(lock) WRITE_REG(`LOCK8(0), 8'h0);
   end
   else if(WIDTH == 16)
   begin
      if(lock) WRITE_REG(`LOCK16(0), 16'hd9);
      WRITE_REG(`IRQ_CTRL16(0), 16'h0);
      if(lock) WRITE_REG(`LOCK16(0), 16'h0);
   end
   else if(WIDTH == 32)
   begin
      if(lock) WRITE_REG(`LOCK32, 32'hd9);
      WRITE_REG(`IRQ_CTRL32, 32'h0);
      if(lock) WRITE_REG(`LOCK32, 32'h0);
   end
end
endtask

task API_WDT_ENABLE_IRQ(input [31:0] value, input lock);
begin
   if(WIDTH == 8)
   begin
      if(lock) WRITE_REG(`LOCK8(0), 8'hd9);
      WRITE_REG(`IRQ_CTRL8(0), value[7:0]);
      if(lock) WRITE_REG(`LOCK8(0), 8'h0);
   end
   else if(WIDTH == 16)
   begin
      if(lock) WRITE_REG(`LOCK16(0), 16'hd9);
      WRITE_REG(`IRQ_CTRL16(0), value[15:0]);
      if(lock) WRITE_REG(`LOCK16(0), 16'h0);
   end
   else if(WIDTH == 32)
   begin
      if(lock) WRITE_REG(`LOCK32, 32'hd9);
      WRITE_REG(`IRQ_CTRL32, value[31:0]);
      if(lock) WRITE_REG(`LOCK32, 32'h0);
   end
end
endtask

task API_WDT_CLEAR_IRQ(input [31:0] value, input lock);
begin
   if(WIDTH == 8)
   begin
      if(lock) WRITE_REG(`LOCK8(0), 8'hd9);
      WRITE_REG(`IRQ_FLAG8(0), value[7:0]);
      if(lock) WRITE_REG(`LOCK8(0), 8'h0);
   end
   else if(WIDTH == 16)
   begin
      if(lock) WRITE_REG(`LOCK16(0), 16'hd9);
      WRITE_REG(`IRQ_FLAG16(0), value[15:0]);
      if(lock) WRITE_REG(`LOCK16(0), 16'h0);
   end
   else if(WIDTH == 32)
   begin
      if(lock) WRITE_REG(`LOCK32, 32'hd9);
      WRITE_REG(`IRQ_FLAG32, value[31:0]);
      if(lock) WRITE_REG(`LOCK32, 32'h0);
   end
end
endtask

task API_WDT_GET_IRQ; // return value 'rv'
begin
   rv = 0;
   if(WIDTH == 8)
      READ_REG(`IRQ_FLAG8(0));
   else if(WIDTH == 16)
      READ_REG(`IRQ_FLAG16(0));
   else if(WIDTH == 32)
      READ_REG(`IRQ_FLAG32);
end
endtask
