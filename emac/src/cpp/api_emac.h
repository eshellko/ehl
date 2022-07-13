// Design:           Ethernet
// Revision:         1.0
// Date:             2022-07-13
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2022-07-13 A.Kornukhin: Initial release
// Description:      Control & Status Registers (CSR) Structure & API Definition

//--------------------------------------------
// Structure definition
//--------------------------------------------
struct EHL_EMAC
{
   volatile unsigned int TX_CTRL;

   volatile unsigned int MCR;
   volatile unsigned int MDR;
};
//--------------------------------------------
// APIs for 32-bit wide systems
// DESCRIPTION
//   API_EMAC_INIT               -- initialize MAC
//   API_EMAC_DISABLE_IRQ        -- disable IRQs
//   API_EMAC_ENABLE_IRQ         -- enable selected IRQs
//   API_EMAC_CLEAR_IRQ          -- clear selected IRQ flags
//   API_EMAC_GET_IRQ            -- get IRQ vector
//--------------------------------------------
void API_EMAC_INIT(struct EHL_EMAC* dev_id)
{
}
//
// Interrupt routines
//
void API_EMAC_DISABLE_IRQ(struct EHL_EMAC* dev_id)
{
   dev_id->IRQ_CTRL = 0;
}
void API_EMAC_ENABLE_IRQ(struct EHL_EMAC* dev_id, int value)
{
   dev_id->IRQ_CTRL = value;
}
void API_EMAC_CLEAR_IRQ(struct EHL_EMAC* dev_id, int value)
{
   dev_id->IRQ_FLAG = value;
}
unsigned int API_EMAC_GET_IRQ(struct EHL_EMAC* dev_id)
{
   return dev_id->IRQ_FLAG;
}
