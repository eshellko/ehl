// Design:           LSSI
// Revision:         1.0
// Date:             2022-07-05
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2022-07-05 A.Kornukhin: Initial release
//--------------------------------------------
// Structure definition
//--------------------------------------------
struct EHL_LSSI
{
   volatile unsigned int CTRL;
   volatile unsigned int STAT;
   volatile unsigned int CFG;
   volatile unsigned int SSR;
   volatile unsigned int FCR;
   volatile unsigned int FSR;
   volatile unsigned int CDR;
   volatile unsigned int IER;
   volatile unsigned int IFR;
   volatile unsigned int IMR;
   volatile unsigned int IOCFG;
   volatile unsigned int DR;
   volatile unsigned int RAS;
   volatile unsigned int UFCR;
   volatile unsigned int TXFIFO_LVL;
   volatile unsigned int RXFIFO_LVL;
};
//--------------------------------------------
// APIs for 32-bit wide systems
// DESCRIPTION
//   API_LSSI_SET_UART          -- set UART mode
//   API_LSSI_SET_SPI           -- set SPI mode
//   API_UART_ENABLE            -- enable UART transmit and receive
//   API_UART_DISABLE           -- disable UART transmit and receive
//   API_UART_SET_WORD_LENGTH   -- set UART data bits
//   API_UART_SET_PARITY        -- set UART parity mode
//   API_LSSI_CHARS_AVAIL       -- there are any characters in the receive FIFO
//   API_LSSI_SPACE_AVAIL       -- there is any space in the transmit FIFO
//   API_LSSI_TX_CHAR           -- write single character to LSSI
//   API_LSSI_TX_CHAR_BLOCK     -- write single character to LSSI (wait for success write into FIFO)
//   API_LSSI_TX_BUFFER         -- write buffer to LSSI (until there is space)
//   API_LSSI_TX_BUFFER_BLOCK   -- write buffer to LSSI (wait for success write to FIFO)
//   API_LSSI_RX_CHAR           -- read single character from LSSI
//   API_LSSI_RX_CHAR_BLOCK     -- read single character from LSSI (wait for success read from FIFO)
//   API_LSSI_RX_BUFFER         -- read buffer from LSSI
//   API_LSSI_RX_BUFFER_BLOCK   -- read buffer from LSSI (wait for success read from FIFO)
//   API_UART_TX_BUSY           -- wait UART completes transmission
//   API_SPI_M_BUSY             -- wait SPI Controller completes transmission
//   API_LSSI_RX_FLUSH          -- flush data in LSSI receive FIFO
//   API_LSSI_SET_FIFO_LEVEL    -- set LSSI interrupt generation FIFO level
//   API_LSSI_DISABLE_IRQ       -- disable IRQs
//   API_LSSI_ENABLE_IRQ        -- enable selected IRQs
//   API_LSSI_CLEAR_IRQ         -- clear selected IRQ flags
//   API_LSSI_GET_IRQ           -- get IRQ vector
//--------------------------------------------
void API_LSSI_SET_UART(struct EHL_LSSI* dev_id)
{
   dev_id->CFG |= 0x1;
}
void API_LSSI_SET_SPI(struct EHL_LSSI* dev_id, int phase, int polarity, int trgt_m)
{
   dev_id->CFG = (dev_id->CFG & 0xFFFFFF1E) | ((polarity & 1) << 5) | ((phase & 1) << 6) | ((trgt_m & 1) << 7);
}
void API_UART_ENABLE(struct EHL_LSSI* dev_id)
{
   dev_id->CTRL = 0x6; // RE | TE
}
void API_UART_DISABLE(struct EHL_LSSI* dev_id)
{
   // disable the UART
   dev_id->CTRL = 0;
   // wait for the end of transmission of the current character
   while(dev_id->STAT & 0x4);
   // flush the transmit FIFO
   dev_id->FCR |= 0x40;
}
// return value:
// 0 - success
// 1 - error, incorrect value provided
int API_UART_SET_WORD_LENGTH(struct EHL_LSSI* dev_id, int value)
{
   switch(value)
   {
      case (5) : dev_id->CFG = (dev_id->CFG & 0xFFFFFFE7) | 0x18; break;
      case (6) : dev_id->CFG = (dev_id->CFG & 0xFFFFFFE7) | 0x10; break;
      case (7) : dev_id->CFG = (dev_id->CFG & 0xFFFFFFE7) | 0x08; break;
      case (8) : dev_id->CFG = (dev_id->CFG & 0xFFFFFFE7); break;
      default : return 1;
   }
   return 0;
}
// return value:
// 0 - success
// 1 - error, incorrect value provided (NONE, EVEN, or ODD)
int API_UART_SET_PARITY(struct EHL_LSSI* dev_id, int value)
{
   if(value > 2) return 1;
   dev_id->RAS = value & 0x3;
   return 0;
}
// 0 - there is no data - FIFO empty
// 1 - there is data
int API_LSSI_CHARS_AVAIL(struct EHL_LSSI* dev_id)
{
   if(dev_id->FSR & 0x8) return 0;
   else return 1;
}
// 0 - there is no space - FIFO full
// 1 - space available
int API_LSSI_SPACE_AVAIL(struct EHL_LSSI* dev_id)
{
   if(dev_id->FSR & 0x1) return 0;
   else return 1;
}
// return value:
// 0 - data placed into FIFO
// 1 - there is no space in FIFO
int API_LSSI_TX_CHAR(struct EHL_LSSI* dev_id, char value)
{
   if(API_LSSI_SPACE_AVAIL(dev_id) == 0) return 1;
   dev_id->DR = value;
   return 0;
}
void API_LSSI_TX_CHAR_BLOCK(struct EHL_LSSI* dev_id, char value)
{
   // wait until there is place into FIFO - lock is possible if transmit is disabled, flow control inhibit, or any other reason to not read from FIFO
   while(API_LSSI_SPACE_AVAIL(dev_id) == 0);
   dev_id->DR = value;
}
// return value:
// 0 - whole data placed into FIFO
// non-0 - not all bytes placed into FIFO - returned value is the number of transmit characters +1
int API_LSSI_TX_BUFFER(struct EHL_LSSI* dev_id, char* buffer, int len)
{
// sends data while there is place in transmit FIFO
   int i = 0;
   for(i = 0; i < len; i++)
      if(API_LSSI_TX_CHAR(dev_id, buffer[i])) return (i+1);
   return 0;
}
void API_LSSI_TX_BUFFER_BLOCK(struct EHL_LSSI* dev_id, char* buffer, int len)
{
// send whole provided data, lock is possible inside API_LSSI_TX_CHAR_BLOCK
   int i = 0;
   for(i = 0; i < len; i++)
      API_LSSI_TX_CHAR_BLOCK(dev_id, buffer[i]);
}
// return value:
// 0 - success
// 1 - error, there is no data
int API_LSSI_RX_CHAR(struct EHL_LSSI* dev_id, char* data)
{
   if(!API_LSSI_CHARS_AVAIL(dev_id)) return 1;
   data[0] = dev_id->DR;
   return 0;
}
// return value:
// data byte
char API_LSSI_RX_CHAR_BLOCK(struct EHL_LSSI* dev_id)
{
   while(!API_LSSI_CHARS_AVAIL(dev_id));
   return dev_id->DR;
}
// return value:
// 0 - success
// 1 - error, there is no data
int API_LSSI_RX_BUFFER(struct EHL_LSSI* dev_id, char* buffer, int len)
{
   int i = 0;
   for(i = 0; i < len; i++)
      if(API_LSSI_RX_CHAR(dev_id, &buffer[i])) return (i+1);
   return 0;
}
void API_LSSI_RX_BUFFER_BLOCK(struct EHL_LSSI* dev_id, char* buffer, int len)
{
   int i = 0;
   for(i = 0; i < len; i++)
      buffer[i] = API_LSSI_RX_CHAR_BLOCK(dev_id);
}
void API_UART_TX_BUSY(struct EHL_LSSI* dev_id)
{
// wait Tx FIFO is not empty
   while(!(dev_id->FSR & 0x2));
// wait shift register empty
   while(dev_id->STAT & 0x4);
}
void API_SPI_M_BUSY(struct EHL_LSSI* dev_id)
{
// wait Tx FIFO is not empty
   while(!(dev_id->FSR & 0x2));
// wait shift register empty
   while(dev_id->STAT & 0x1);
}
void API_LSSI_RX_FLUSH(struct EHL_LSSI* dev_id)
{
   dev_id->FCR |= 0x80;
}
void API_LSSI_SET_FIFO_LEVEL(struct EHL_LSSI* dev_id, int txfifo_level, int rxfifo_level)
{
   dev_id->TXFIFO_LVL = txfifo_level;
   dev_id->RXFIFO_LVL = rxfifo_level;
}
//
// Interrupt routines
//
void API_LSSI_DISABLE_IRQ(struct EHL_LSSI* dev_id)
{
   dev_id->IER = 0;
}
void API_LSSI_ENABLE_IRQ(struct EHL_LSSI* dev_id, int value)
{
   dev_id->IER = value;
}
void API_LSSI_CLEAR_IRQ(struct EHL_LSSI* dev_id, int value)
{
   dev_id->IFR = value;
}
unsigned int API_LSSI_GET_IRQ(struct EHL_LSSI* dev_id)
{
   return dev_id->IFR;
}
/*
void sw_uart_clear_rx_overrun(struct sw_uart_reg* base_adr)
{
   unsigned int tmp = read_generic_reg((ehl_ptr_t)&base_adr->ucr);
   write_generic_reg((ehl_ptr_t)&base_adr->ucr, tmp | 0x10);
}

//
// 0 - LSB first
// 1 - MSB first
void sw_uart_set_bit_order(struct sw_uart_reg* base_adr, unsigned int value)
{
   unsigned int tmp = read_generic_reg((ehl_ptr_t)&base_adr->ucr);
   write_generic_reg((ehl_ptr_t)&base_adr->ucr, (tmp&0xFB) | (value<<1));
}
*/
/*
// SSR
void sw_spi_set_cs(struct sw_spi_reg* base_adr, unsigned char cs)
{
   write_generic_reg((ehl_ptr_t)&base_adr->ssr, cs);
}
void sw_spi_cs_set_bit(struct sw_spi_reg* base_adr, int bit_num)
{
   unsigned int tmp = read_generic_reg((ehl_ptr_t)&base_adr->ssr);
   switch(bit_num)
   {
      case 0 : write_generic_reg((ehl_ptr_t)&base_adr->ssr, tmp | 0x1); break;
      case 1 : write_generic_reg((ehl_ptr_t)&base_adr->ssr, tmp | 0x2); break;
      case 2 : write_generic_reg((ehl_ptr_t)&base_adr->ssr, tmp | 0x4); break;
      case 3 : write_generic_reg((ehl_ptr_t)&base_adr->ssr, tmp | 0x8); break;
      case 4 : write_generic_reg((ehl_ptr_t)&base_adr->ssr, tmp | 0x10); break;
      case 5 : write_generic_reg((ehl_ptr_t)&base_adr->ssr, tmp | 0x20); break;
      case 6 : write_generic_reg((ehl_ptr_t)&base_adr->ssr, tmp | 0x40); break;
      case 7 : write_generic_reg((ehl_ptr_t)&base_adr->ssr, tmp | 0x80); break;
   }
}
void sw_spi_cs_clear_bit(struct sw_spi_reg* base_adr, int bit_num)
{
   unsigned int tmp = read_generic_reg((ehl_ptr_t)&base_adr->ssr);
   switch(bit_num)
   {
      case 0 : write_generic_reg((ehl_ptr_t)&base_adr->ssr, tmp & 0xFE); break;
      case 1 : write_generic_reg((ehl_ptr_t)&base_adr->ssr, tmp & 0xFD); break;
      case 2 : write_generic_reg((ehl_ptr_t)&base_adr->ssr, tmp & 0xFB); break;
      case 3 : write_generic_reg((ehl_ptr_t)&base_adr->ssr, tmp & 0xF7); break;
      case 4 : write_generic_reg((ehl_ptr_t)&base_adr->ssr, tmp & 0xEF); break;
      case 5 : write_generic_reg((ehl_ptr_t)&base_adr->ssr, tmp & 0xDF); break;
      case 6 : write_generic_reg((ehl_ptr_t)&base_adr->ssr, tmp & 0xBF); break;
      case 7 : write_generic_reg((ehl_ptr_t)&base_adr->ssr, tmp & 0x7F); break;
   }
}
unsigned char sw_spi_get_cs(struct sw_spi_reg* base_adr)
{
   unsigned int tmp = read_generic_reg((ehl_ptr_t)&base_adr->ssr);
   return tmp & 0xFF;
}
*/
