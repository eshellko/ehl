// Design:           GPIO
// Revision:         1.0
// Date:             2022-07-04
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2022-07-04 A.Kornukhin: Initial release
// Description:      Control & Status Registers (CSR) Structure & API Definition
//                   This API utilizes 32 bit I/O to the GPIO registers.
//                   With less than 32 bits, the unused bits from registers
//                   are read as zero and written as don't cares.
// Notes:            APIs are compatible with 'ehl_gpio_top' controller that
//                   implemented with the following parameters
// GPIO data output register (GDOR)
//   GDOR_ENA = 5'b111x1
// GPIO output enable register (GOER)
//   GOER_ENA = 5'bxxxx1
// GPIO alternative function register (GAFR)
//   GAFR_ENA = 5'bxxxx1
// GPIO pull enable register (GPER)
//   GPER_ENA = 5'bxxxx1
// GPIO pull type register (GPTR)
//   GPTR_ENA = 5'bxxxx1
// GPIO interrupt enable register (GIER)
//   GIER_ENA = 5'bxxxx1
// GPIO interrupt source register (GISR)
//   GISR_ENA = 5'bxxxx1
// GPIO interrupt flag register (GIFR)
//   READ_GIFR_ENA = 1
//   CLR_GIFR_ENA = 1
// GPIO Data input register (GDIR)
//   READ_GDIR_ENA = 1
// GPIO capture mode register (GCMR)
//   GCMR_ENA = 5'bxxxx1
// GPIO filter mode register (GFMR)
//   GFMR_ENA = 5'bxxxx1
//--------------------------------------------
// Structure definition
//--------------------------------------------
struct CSR_EHL_GPIO
{
   volatile unsigned int REG;
   volatile unsigned int SET;
   volatile unsigned int CLR;
   volatile unsigned int INV;
};

struct EHL_GPIO
{
   struct CSR_EHL_GPIO GDOR;
   struct CSR_EHL_GPIO GOER;
   struct CSR_EHL_GPIO GAFR;
   struct CSR_EHL_GPIO GPER;
   struct CSR_EHL_GPIO GPTR;
   struct CSR_EHL_GPIO GIER;
   struct CSR_EHL_GPIO GISR;
   struct CSR_EHL_GPIO GIFR;
   struct CSR_EHL_GPIO GDIR;
   struct CSR_EHL_GPIO GCMR;
   struct CSR_EHL_GPIO GFMR;
};
//--------------------------------------------
// APIs for 32-bit wide systems
// DESCRIPTION
//   API_GPIO_INIT              -- initialize GPIO
//   API_GPIO_WRITE             -- write GPIO value
//   API_GPIO_READ_BIT          -- read value of GPIO pin
//   API_GPIO_WRITE_BIT         -- write value of GPIO pin
//   API_GPIO_SET_BIT           -- set value of GPIO pin
//   API_GPIO_CLEAR_BIT         -- clear value of GPIO pin
//   API_GPIO_TOGGLE_BIT        -- toggle current value of GPIO pin
//   API_GPIO_DISABLE_IRQ       -- disable IRQs
//   API_GPIO_ENABLE_IRQ        -- enable selected IRQs
//   API_GPIO_CLEAR_IRQ         -- clear selected IRQ flags
//   API_GPIO_GET_IRQ           -- get IRQ vector
//--------------------------------------------
//
// Initialize GPIO
//
void API_GPIO_INIT(struct EHL_GPIO* dev_id, int direction, int pull_up, int pull_down, int filter, int int_rise, int int_any,
		   int altf, int value_init)
{
// 'pull_up' has higher priority
   dev_id->GPER.REG = pull_up | pull_down;
   dev_id->GPTR.REG = pull_up;

   dev_id->GOER.REG = direction;
   dev_id->GFMR.REG = filter;
// 'int_any' has higher priority
   dev_id->GCMR.REG = int_any;
   dev_id->GISR.REG = int_rise;

   dev_id->GAFR.REG = altf;
   dev_id->GDOR.REG = value_init;
}
//
//
//
void API_GPIO_WRITE(struct EHL_GPIO* dev_id, int value)
{
   dev_id->GDOR.REG = value;
}
//
// Bit operations
//
unsigned int API_GPIO_READ_BIT(struct EHL_GPIO* dev_id, int idx)
{
   return (dev_id->GDIR.REG >> idx) & 1;
}
void API_GPIO_WRITE_BIT(struct EHL_GPIO* dev_id, int idx, int value)
{
//   if(value & 0x1) dev_id->GDOR.REG |= (1 << idx);
//   else            dev_id->GDOR.REG &= (~(1 << idx));
   if(value & 0x1) dev_id->GDOR.SET = (1 << idx);
   else            dev_id->GDOR.CLR = (1 << idx);
}
void API_GPIO_SET_BIT(struct EHL_GPIO* dev_id, int idx)
{
   dev_id->GDOR.SET = (1 << idx);
}
void API_GPIO_CLEAR_BIT(struct EHL_GPIO* dev_id, int idx)
{
   dev_id->GDOR.CLR = (~(1 << idx));
}
void API_GPIO_TOGGLE_BIT(struct EHL_GPIO* dev_id, int idx)
{
   dev_id->GDOR.INV = (1 << idx);
}
//
// Interrupt routines
//
void API_GPIO_DISABLE_IRQ(struct EHL_GPIO* dev_id)
{
   dev_id->GIER.REG = 0;
}
void API_GPIO_ENABLE_IRQ(struct EHL_GPIO* dev_id, int value)
{
   dev_id->GIER.REG = value;
}
void API_GPIO_CLEAR_IRQ(struct EHL_GPIO* dev_id, int value)
{
// Note: clear uses CLR and not REG
   dev_id->GIFR.CLR = value;
}
unsigned int API_GPIO_GET_IRQ(struct EHL_GPIO* dev_id)
{
   return dev_id->GIFR.REG;
}
