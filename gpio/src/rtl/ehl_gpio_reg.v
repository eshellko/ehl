// Design:           GPIO Register
// Revision:         1.1
// Date:             2020-09-18
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2011-12-28 A.Kornukhin: initial release
//                   1.1 2020-09-18 A.Kornukhin: register access refined

module ehl_gpio_reg
#(
   parameter WIDTH = 32,
   parameter REG_INIT = 0
)
(
   input wire clk, reset_n, write_reg,
   input wire [WIDTH-1:0] data_in, set_reg, clr_reg, inv_reg,
   output reg [WIDTH-1:0] gpio_register
);
   always@(posedge clk or negedge reset_n)
   if(!reset_n)
      gpio_register <= REG_INIT[WIDTH-1:0];
   else if(write_reg)
      gpio_register <= data_in;
   else
      gpio_register <= ((gpio_register | set_reg) & ~clr_reg) ^ inv_reg; // Q: modify order of mutually exclusive operations to improve QoR?

endmodule
