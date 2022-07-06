// Design:           Interrupt Controller
// Revision:         1.0
// Date:             2022-07-06
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2022-07-06 A.Kornukhin: Initial release
//--------------------------------------------
// Structure definition
//--------------------------------------------
struct EHL_INTC
{
   volatile unsigned int IP;
   volatile unsigned int reserved[3];
   volatile unsigned int PRIO[16];
   volatile unsigned int reserved2[4];
   volatile unsigned int IE;
   volatile unsigned int THRESH;
   volatile unsigned int CC;
};
//--------------------------------------------
// APIs for 32-bit wide systems
// DESCRIPTION
//   API_INTC_MASTER_INT_ENABLE   -- enable interrupts signaling -- TODO: check functionality requirement
//   API_INTC_MASTER_INT_DISABLE  -- disable interrupts signaling -- TODO: check functionality requirement
//   API_INTC_INT_ENABLE          -- enable selected interrupt generation
//   API_INTC_INT_DISABLE         -- disable selected interrupt generation
//   API_INTC_PRIORITY_SET        -- set interrupt priority
//   API_INTC_PRIORITY_GET        -- get interrupt priority
//   API_INTC_THRESH_SET          -- set interrupt priority threshold
//   API_INTC_THRESH_GET          -- get interrupt priority threshold
//   API_INTC_INT_VECTOR_GET      -- get vector of pended interrupts
//   API_INTC_CLAIM               -- start current interrupt handling
//   API_INTC_COMPLETE            -- complete current interrupt handling
//--------------------------------------------
void API_INTC_INT_ENABLE(struct EHL_INTC* dev_id, int value)
{
   dev_id->IE |= value;
}
void API_INTC_INT_DISABLE(struct EHL_INTC* dev_id, int value)
{
   dev_id->IE &= ~(value);
}
// TODO: report error, if access to PRIO[0]
// TODO: report error, if value exceed limit
void API_INTC_PRIORITY_SET(struct EHL_INTC* dev_id, int idx, int value)
{
   dev_id->PRIO[idx] = value;
}
// TODO: report error if OOB
int API_INTC_PRIORITY_GET(struct EHL_INTC* dev_id, int idx)
{
   return dev_id->PRIO[idx];
}
void API_INTC_THRESH_SET(struct EHL_INTC* dev_id, int value)
{
   dev_id->THRESH = value;
}
int API_INTC_THRESH_GET(struct EHL_INTC* dev_id)
{
   return dev_id->THRESH;
}
int API_INTC_INT_VECTOR_GET(struct EHL_INTC* dev_id)
{
   return dev_id->IP;
}
int API_INTC_CLAIM(struct EHL_INTC* dev_id)
{
   return dev_id->CC;
}
void API_INTC_COMPLETE(struct EHL_INTC* dev_id, int value)
{
   dev_id->CC = value;
}
