// Design:           Timer
// Revision:         1.0
// Date:             2022-06-01
// Company:          Eshell
// Designer:         A.Kornukhin (kornukhin@mail.ru)
// Last modified by: 1.0 2022-06-01 A.Kornukhin: Initial release
// Description:      Control & Status Registers (CSR) Structure & API Definition
//--------------------------------------------
// Structure definition
//--------------------------------------------
struct CSR_EHL_TIMER
{
   volatile unsigned int CFG;
   volatile unsigned int CTRL;
   volatile unsigned int CTRL_ALL;
   volatile unsigned int DEAD;
   volatile unsigned int LOAD;
   volatile unsigned int PRE;
   volatile unsigned int VALUE;
   volatile unsigned int CPT;
   volatile unsigned int IRQ_CTRL;
   volatile unsigned int IRQ_FLAG;
   volatile unsigned int CMPA_T0;
   volatile unsigned int CMPA_T1;
   volatile unsigned int CMPB_T0;
   volatile unsigned int CMPB_T1;
   volatile unsigned int CMPC_T0;
   volatile unsigned int CMPC_T1;
};
struct EHL_TIMER
{
   struct CSR_EHL_TIMER TMR[4];
};
//--------------------------------------------
// APIs for 32-bit wide systems
// DESCRIPTION
//   API_TIMER_SET_PERIOD        -- set base timer period
//   API_TIMER_SET_DEADTIME      -- set PWM dead time
//   API_TIMER_SET_COMPARE_A_T0  -- set channel A comparator lower bound
//   API_TIMER_SET_COMPARE_A_T1  -- set channel A comparator upper bound
//   API_TIMER_SET_COMPARE_B_T0  -- set channel B comparator lower bound
//   API_TIMER_SET_COMPARE_B_T1  -- set channel B comparator upper bound
//   API_TIMER_SET_COMPARE_C_T0  -- set channel C comparator lower bound
//   API_TIMER_SET_COMPARE_C_T1  -- set channel C comparator upper bound
//   API_TIMER_SET_ONESHOT       -- set one-shot mode
//   API_TIMER_SET_CYCLIC        -- set cyclic mode
//   API_TIMER_PWM_COMP_ENA      -- enable PWM complementary outputs
//   API_TIMER_PWM_COMP_DISA     -- disable PWM complementary outputs
//   API_TIMER_SET_INCR          -- set incrementing counter
//   API_TIMER_SET_DECR          -- set decremeting counter
//   API_TIMER_SET_COMPARE       -- setup "compare" mode
//   API_TIMER_SET_PWM           -- setup "pwm" mode
//   API_TIMER_SET_COUNTER       -- setup "counter" mode
//   API_TIMER_SET_CAPTURE       -- setup "capture" mode
//   API_TIMER_SET_TIMER         -- setup "timer" mode
//   API_TIMER_SET_PRESCALER     -- set clock divider
//   API_TIMER_GET_VALUE         -- get base timer current value
//   API_TIMER_GET_CAPTURE       -- get capture register value
//   API_TIMER_GET_CTRL          -- get control register
//   API_TIMER_START             -- start timer
//   API_TIMER_STOP              -- stop timer
//   API_TIMER_PAUSE             -- pause timer
//   API_TIMER_CTRL_ALL          -- control all timers at once
//   API_TIMER_DISABLE_IRQ       -- disable IRQs
//   API_TIMER_ENABLE_IRQ        -- enable selected IRQs
//   API_TIMER_CLEAR_IRQ         -- clear selected IRQ flags
//   API_TIMER_GET_IRQ           -- get IRQ vector
//--------------------------------------------
void API_TIMER_SET_PERIOD(struct EHL_TIMER* dev_id, int timer, int value)
{
   dev_id->TMR[timer].LOAD = value;
}
void API_TIMER_SET_DEADTIME(struct EHL_TIMER* dev_id, int timer, int value)
{
   dev_id->TMR[timer].DEAD = value;
}
void API_TIMER_SET_COMPARE_A_T0(struct EHL_TIMER* dev_id, int timer, int value)
{
   dev_id->TMR[timer].CMPA_T0 = value;
}
void API_TIMER_SET_COMPARE_A_T1(struct EHL_TIMER* dev_id, int timer, int value)
{
   dev_id->TMR[timer].CMPA_T1 = value;
}
void API_TIMER_SET_COMPARE_B_T0(struct EHL_TIMER* dev_id, int timer, int value)
{
   dev_id->TMR[timer].CMPB_T0 = value;
}
void API_TIMER_SET_COMPARE_B_T1(struct EHL_TIMER* dev_id, int timer, int value)
{
   dev_id->TMR[timer].CMPB_T1 = value;
}
void API_TIMER_SET_COMPARE_C_T0(struct EHL_TIMER* dev_id, int timer, int value)
{
   dev_id->TMR[timer].CMPC_T0 = value;
}
void API_TIMER_SET_COMPARE_C_T1(struct EHL_TIMER* dev_id, int timer, int value)
{
   dev_id->TMR[timer].CMPC_T1 = value;
}
void API_TIMER_SET_ONESHOT(struct EHL_TIMER* dev_id, int timer)
{
   dev_id->TMR[timer].CFG |= 0x20000; // 2 in 3-rd byte;
}
void API_TIMER_SET_CYCLIC(struct EHL_TIMER* dev_id, int timer)
{
   dev_id->TMR[timer].CFG &= 0xFFFDFFFF; // 2 in 3-rd byte
}
void API_TIMER_PWM_COMP_ENA(struct EHL_TIMER* dev_id, int timer)
{
   dev_id->TMR[timer].CFG |= 0x40000; // 3 in 3-rd byte;
}
void API_TIMER_PWM_COMP_DISA(struct EHL_TIMER* dev_id, int timer)
{
   dev_id->TMR[timer].CFG &= 0xFFFBFFFF; // 3 in 3-rd byte
}
void API_TIMER_SET_INCR(struct EHL_TIMER* dev_id, int timer)
{
   dev_id->TMR[timer].CFG |= 0x10000;
}
void API_TIMER_SET_DECR(struct EHL_TIMER* dev_id, int timer)
{
   dev_id->TMR[timer].CFG &= 0xFFFEFFFF;
}
void API_TIMER_SET_COMPARE(struct EHL_TIMER* dev_id, int timer, int channel_en, int cmp_mode)
{
   volatile unsigned int rv = dev_id->TMR[timer].CFG;
   dev_id->TMR[timer].CFG = (rv & 0xFFFFFF00) | 2 | (channel_en << 3) | (cmp_mode << 6);
}
void API_TIMER_SET_PWM(struct EHL_TIMER* dev_id, int timer, int channel_en)
{
   volatile unsigned int rv = dev_id->TMR[timer].CFG;
   dev_id->TMR[timer].CFG = (rv & 0xFFFFFF00) | 3 | (channel_en << 3);
}
void API_TIMER_SET_COUNTER(struct EHL_TIMER* dev_id, int timer, int channel, int ttype)
{
   volatile unsigned int rv = dev_id->TMR[timer].CFG;
   dev_id->TMR[timer].CFG = (rv & 0xFFFFF800) | 4 | (channel << 8) | (ttype << 9);
}
void API_TIMER_SET_CAPTURE(struct EHL_TIMER* dev_id, int timer, int channel, int ttype, int start, int stop)
{
   volatile unsigned int rv = dev_id->TMR[timer].CFG;
   dev_id->TMR[timer].CFG = (rv & 0xFFFF00F8) | 1 | (channel << 8) | (ttype << 9) | (start << 11) | (stop << 13);
}
void API_TIMER_SET_TIMER(struct EHL_TIMER* dev_id, int timer)
{
   dev_id->TMR[timer].CFG &= 0xFFFFFF00;
}
void API_TIMER_SET_PRESCALER(struct EHL_TIMER* dev_id, int timer, int value)
{
   dev_id->TMR[timer].PRE = value;
}
unsigned int API_TIMER_GET_VALUE(struct EHL_TIMER* dev_id, int timer)
{
   return dev_id->TMR[timer].VALUE;
}
unsigned int API_TIMER_GET_CAPTURE(struct EHL_TIMER* dev_id, int timer)
{
   return dev_id->TMR[timer].CPT;
}
unsigned int API_TIMER_GET_CTRL(struct EHL_TIMER* dev_id, int timer)
{
   return dev_id->TMR[timer].CTRL;
}
void API_TIMER_START(struct EHL_TIMER* dev_id, int timer)
{
   dev_id->TMR[timer].CTRL = 1;
}
void API_TIMER_STOP(struct EHL_TIMER* dev_id, int timer)
{
   dev_id->TMR[timer].CTRL = 0;
}
void API_TIMER_PAUSE(struct EHL_TIMER* dev_id, int timer)
{
   dev_id->TMR[timer].CTRL = 3;
}
void API_TIMER_CTRL_ALL(struct EHL_TIMER* dev_id, int value)
{
   dev_id->TMR[0].CTRL_ALL = value;
}
//
// Interrupt routines
//
void API_TIMER_DISABLE_IRQ(struct EHL_TIMER* dev_id)
{
   dev_id->TMR[0].IRQ_CTRL = 0;
}
void API_TIMER_ENABLE_IRQ(struct EHL_TIMER* dev_id, int value)
{
   dev_id->TMR[0].IRQ_CTRL = value;
}
void API_TIMER_CLEAR_IRQ(struct EHL_TIMER* dev_id, int value)
{
   dev_id->TMR[0].IRQ_FLAG = value;
}
unsigned int API_TIMER_GET_IRQ(struct EHL_TIMER* dev_id)
{
   return dev_id->TMR[0].IRQ_FLAG;
}
