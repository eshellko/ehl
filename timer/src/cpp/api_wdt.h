// Design:           Watchdog
// Revision:         1.0
// Date:             2022-07-11
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2022-07-11 A.Kornukhin: Initial release
//--------------------------------------------
// Structure definition
//--------------------------------------------
struct EHL_WDT
{
   volatile unsigned int LOAD;
   volatile unsigned int VAL;
   volatile unsigned int LOCK;
   volatile unsigned int IRQ_CTRL;
   volatile unsigned int IRQ_FLAG;
};
//--------------------------------------------
// APIs for 32-bit wide systems
// DESCRIPTION
//   API_WDT_START              -- start watchdog
//   API_WDT_STOP               -- stop watchdog
//   API_WDT_GET_TIMEOUT        -- get watchdog interval
//   API_WDT_GET_INTERVAL       -- get current watchdog timer value
//   API_WDT_ACTIVE             -- define if timer is run
//   API_WDT_DISABLE_IRQ        -- disable IRQs
//   API_WDT_ENABLE_IRQ         -- enable selected IRQs
//   API_WDT_CLEAR_IRQ          -- clear selected IRQ flags
//   API_WDT_GET_IRQ            -- get IRQ
//--------------------------------------------
void API_WDT_START(struct EHL_WDT* dev_id, unsigned int value, bool lock = true)
{
   if(lock) dev_id->LOCK = 0xd9;
   dev_id->LOAD = value;
   if(lock) dev_id->LOCK = 0x0;
}
void API_WDT_STOP(struct EHL_WDT* dev_id, bool lock = true)
{
   if(lock) dev_id->LOCK = 0xd9;
   dev_id->LOAD = 0;
   if(lock) dev_id->LOCK = 0x0;
}
int API_WDT_GET_TIMEOUT(struct EHL_WDT* dev_id)
{
   return dev_id->LOAD;
}
int API_WDT_GET_INTERVAL(struct EHL_WDT* dev_id)
{
   return dev_id->VAL;
}
// return value:
// true  - timer is run
// false - timer is stopped
int API_WDT_ACTIVE(struct EHL_WDT* dev_id)
{
   if(API_WDT_GET_INTERVAL(dev_id)) return 1;
   return 0;
}
//
// Interrupt routines
//
void API_WDT_DISABLE_IRQ(struct EHL_WDT* dev_id, bool lock = true)
{
   if(lock) dev_id->LOCK = 0xd9;
   dev_id->IRQ_CTRL = 0;
   if(lock) dev_id->LOCK = 0x0;
}
void API_WDT_ENABLE_IRQ(struct EHL_WDT* dev_id, int value, bool lock = true)
{
   if(lock) dev_id->LOCK = 0xd9;
   dev_id->IRQ_CTRL = value;
   if(lock) dev_id->LOCK = 0x0;
}
void API_WDT_CLEAR_IRQ(struct EHL_WDT* dev_id, int value, bool lock = true)
{
   if(lock) dev_id->LOCK = 0xd9;
   dev_id->IRQ_FLAG = value;
   if(lock) dev_id->LOCK = 0x0;
}
unsigned int API_WDT_GET_IRQ(struct EHL_WDT* dev_id)
{
   return dev_id->IRQ_FLAG;
}
