##############################################################################
# ehl_gpio_apb.sdc --
#
# This file defines constraints for GPIO Controller
#
# Global variables used by these script:
#
# ehl_sdc_hier_prefix - prefix that defines hierarchical location of SPI Controller
#                       Must be set before sourcing this script
#                       Example:
#                          set ehl_sdc_hier_prefix "/top/gpio_inst/"
#                       also, if this prefix not defined, clocks
#                       generated on ports pclk
#                       with default period 10 to allow standalone synthesis
#
# Local variables used by these script.
#
#  APB_CLK       -     Name of APB clock declared externally (default: APB_CLK)
#
##############################################################################
set sdc_version 1.5

if {![info exists APB_CLK]} { set APB_CLK "APB_CLK" }

if {![info exists ehl_sdc_hier_prefix]} {
###############################
# 1) Clock definiton
###############################
   create_clock -name $APB_CLK -period 10 -waveform {0 5}  pclk ; # Note: clock period can be modified to specify actual value
###############################
# 2) IO delays
###############################
   set_input_delay 1.5  -clock $APB_CLK {paddr* pwrite psel penable pwdata*}
   set_output_delay 1.5 -clock $APB_CLK {pready prdata*}

   set_output_delay 1.5 -clock $APB_CLK {ifg}

   # Note: this constraints are generic, point-to-point connectivity with synchronization is used
   set_input_delay 1.5  -clock $APB_CLK {gpio_in*}
   set_output_delay 1.5 -clock $APB_CLK { gpio_out* gpio_oe* gpio_pd* gpio_pu* gpio_en* }

   set ehl_sdc_hier_prefix ""
}
