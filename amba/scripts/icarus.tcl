if [ "$test" == "ahb" ] ; then
   iverilog -D__ehl_assert__ -D__aready__ -I../verification/src/fv/tasks/ -D__ehl_vcd__ -s ehl_ahb2generic_tb -o ehl_ahb2generic_tb.vvp -tvvp src/fv/ehl_ahb2generic_tb.v src/rtl/ehl_ahb2generic.v ../techmap/src/rtl/ehl_spram.v ../techmap/src/rtl/ehl_clock_gate.v
   vvp -l reports/ahb2gen_ivl0.log ehl_ahb2generic_tb.vvp
   rm -fr ehl_ahb2generic_tb.vvp

   iverilog -D__ehl_assert__ -D__spram__ -I../verification/src/fv/tasks/ -D__ehl_vcd__ -s ehl_ahb2generic_tb -o ehl_ahb2generic_tb.vvp -tvvp src/fv/ehl_ahb2generic_tb.v src/rtl/ehl_ahb2generic.v ../techmap/src/rtl/ehl_spram.v ../memory/src/rtl/ehl_spram_ahb_ft.v ../memory/src/rtl/ehl_spram_ft.v ../logic/src/rtl/ehl_mux.v ../fec/src/rtl/ehl_ecc.v ../techmap/src/rtl/ehl_clock_gate.v
   vvp -l reports/ahb2gen_ivl1.log ehl_ahb2generic_tb.vvp
   rm -fr ehl_ahb2generic_tb.vvp

   iverilog -D__ehl_assert__ -I../verification/src/fv/tasks/ -D__ehl_vcd__ -s ehl_ahb2generic_tb -o ehl_ahb2generic_tb.vvp -tvvp src/fv/ehl_ahb2generic_tb.v src/rtl/ehl_ahb2generic.v ../techmap/src/rtl/ehl_spram.v src/rtl/ehl_ahb2core_sync.v ../techmap/src/rtl/ehl_cdc.v ../cdc/src/rtl/ehl_cdc_pulse.v ../techmap/src/rtl/ehl_clock_gate.v
   vvp -l reports/ahb2gen_ivl2.log ehl_ahb2generic_tb.vvp
   rm -fr ehl_ahb2generic_tb.vvp
#elif [ "$test" == "gen" ] ; then
# TODO: add automatic checks
#   iverilog -D__ehl_vcd__ -s sw_generic2ahb_tb -o sw_generic2ahb_tb.vvp -tvvp src/rtl/sw_generic2ahb.v src/fv/sw_generic2ahb_tb.v src/rtl/ehl_ahb2generic.v ../techmap/src/rtl/ehl_spram.v ../memory/src/rtl/ehl_spram_ft.v ../memory/src/rtl/ehl_spram_ahb_ft.v ../fec/src/rtl/ehl_ecc.v ../logic/src/rtl/ehl_mux.v ../verification/src/fv/avip/sw_ahb_avip.v ../techmap/src/rtl/ehl_clock_gate.v
#   vvp -l reports/sw_generic2ahb.log sw_generic2ahb_tb.vvp
#   rm -fr sw_generic2ahb_tb.vvp
elif [ "$test" == "arbiter" ] ; then
   iverilog -g2012 -I ../verification/src/fv/tasks/ -D__ehl_vcd__ -s ehl_ahb_arbiter_tb -o ehl_ahb_arbiter_tb.vvp -tvvp src/rtl/ehl_ahb_arbiter.v src/fv/ehl_ahb_arbiter_tb.v ../logic/src/rtl/ehl_arbiter.v src/rtl/ehl_ahb_stat.v src/rtl/ehl_apb_csr.v src/rtl/ehl_apb2generic.v src/rtl/ehl_ahb_default_slave.v ../techmap/src/rtl/ehl_clock_gate.v
   vvp -l reports/ahb_arb_ivl.log ehl_ahb_arbiter_tb.vvp
   rm -fr ehl_ahb_arbiter_tb.vvp
elif [ "$test" == "ahb_demux" ] ; then
   iverilog -I ../verification/src/fv/tasks/ -D__ehl_vcd__ -s ehl_ahb_demux_tb -o ehl_ahb_demux_tb.vvp -tvvp src/rtl/ehl_ahb_demux.v src/fv/ehl_ahb_demux_tb.v ../memory/src/rtl/ehl_spram_ahb.v src/rtl/ehl_ahb2generic.v ../techmap/src/rtl/ehl_spram.v ../techmap/src/rtl/ehl_clock_gate.v
   vvp -l reports/ahb_demux_ivl.log ehl_ahb_demux_tb.vvp
   rm -fr ehl_ahb_demux_tb.vvp
elif [ "$test" == "extender" ] ; then
# TODO: keep warnings from compilation into log
   iverilog -I ../verification/src/fv/tasks/ -D__ehl_vcd__ -s ehl_axi_extender_tb -o ehl_axi_extender_tb.vvp -tvvp src/rtl/ehl_axi_extender.v src/fv/ehl_axi_extender_tb.v
   vvp -l reports/axi_extender_ivl.log ehl_axi_extender_tb.vvp
   rm -fr ehl_axi_extender_tb.vvp
elif [ "$test" == "apb_demux" ] ; then
   iverilog -I ../verification/src/fv/tasks/ -D__ehl_vcd__ -s ehl_apb_demux_tb -o ehl_apb_demux_tb.vvp -tvvp src/rtl/ehl_apb_demux.v src/fv/ehl_apb_demux_tb.v ../techmap/src/rtl/ehl_cdc.v ../amba/src/rtl/ehl_apb2generic.v ../gpio/src/rtl/ehl_gpio_core.v ../gpio/src/rtl/ehl_gpio_decoder.v ../gpio/src/rtl/ehl_gpio_reg.v ../gpio/src/rtl/ehl_gpio_top.v ../gpio/src/rtl/ehl_gpio_apb.v src/rtl/ehl_apb_csr.v ../gpio/src/rtl/ehl_gpio_filter.v ../techmap/src/rtl/ehl_clock_gate.v
   vvp -l reports/apb_demux_ivl.log ehl_apb_demux_tb.vvp
   rm -fr ehl_apb_demux_tb.vvp
#elif [ "$test" == "ahb_bridge" ] ; then
#   iverilog -I ../verification/src/fv/tasks/ -D__ehl_vcd__ -s ehl_ahb_bridge_tb -o ehl_ahb_bridge_tb.vvp -tvvp src/rtl/ehl_ahb_bridge.v src/fv/ehl_ahb_bridge_tb.v ../techmap/src/rtl/ehl_cdc.v src/rtl/ehl_ahb2generic.v src/rtl/sw_generic2ahb.v
#   vvp -l reports/ehl_ahb_bridge.log ehl_ahb_bridge_tb.vvp
#   rm -fr ehl_ahb_bridge_tb.vvp

elif [ "$test" == "ahb2apb" ] ; then
   iverilog -g2012 -DICARUS -P ehl_ahb2apb_tb.REG_OUT=1 -I ../verification/src/fv/tasks/ -D__ehl_vcd__ -s ehl_ahb2apb_tb -o ehl_ahb2apb_tb.vvp -tvvp src/rtl/ehl_ahb2apb.v src/fv/ehl_ahb2apb_tb.v ../verification/src/fv/avip/sw_apb_avip.v
   vvp -l reports/ahb2apb_ivl1.log ehl_ahb2apb_tb.vvp
   rm -fr ehl_ahb2apb_tb.vvp

   iverilog -g2012 -DICARUS -P ehl_ahb2apb_tb.REG_OUT=0 -I ../verification/src/fv/tasks/ -D__ehl_vcd__ -s ehl_ahb2apb_tb -o ehl_ahb2apb_tb.vvp -tvvp src/rtl/ehl_ahb2apb.v src/fv/ehl_ahb2apb_tb.v ../verification/src/fv/avip/sw_apb_avip.v
   vvp -l reports/ahb2apb_ivl0.log ehl_ahb2apb_tb.vvp
   rm -fr ehl_ahb2apb_tb.vvp
# elif [ "$test" == "axi_mux" ] ; then
#    iverilog -o axi_mux.vvp -I ../verification/src/fv/tasks -s ehl_axi_mux_tb src/fv/ehl_axi_mux_tb.v ../cdc/src/rtl/ehl_sc_fifo.v src/rtl/ehl_axi_mux.v src/rtl/ehl_generic2axi.v ../logic/src/rtl/ehl_arbiter.v
#    vvp -l reports/icarus_axi_mux.log axi_mux.vvp
#    rm -fr axi_mux.vvp
elif [ "$test" == "4k" ] ; then
   iverilog -P ehl_axi_4k_tb.AXI_LEN_WIDTH=8 -P ehl_axi_4k_tb.AXI_DATA_WIDTH=128 -P ehl_axi_4k_tb.AXI_ADDR_WIDTH=32 -o axi_4k.vvp \
      -D __ehl_vcd__ \
      -I ../verification/src/fv/tasks -s ehl_axi_4k_tb src/fv/ehl_axi_4k_tb.v src/rtl/ehl_axi_4kw.v src/rtl/ehl_axi_4kr.v
   vvp -l reports/axi_4k_ivl.log axi_4k.vvp
   rm -fr axi_4k.vvp
elif [ "$test" == "matrix" ] ; then
   iverilog -D ICARUS -s ehl_ahb_matrix_tb src/rtl/ehl_ahb_matrix.v src/rtl/ehl_ahb_default_slave.v src/rtl/ehl_ahb_matrix_in.v src/rtl/ehl_ahb_matrix_out.v ../logic/src/rtl/ehl_arbiter.v src/fv/ehl_ahb_matrix_tb.v \
      -D __ehl_vcd__ \
      -I ../verification/src/fv/tasks -o ahb_matrix.vvp ; # src/rtl/ehl_axi_4kw.v src/rtl/ehl_axi_4kr.v
   vvp -l reports/ahb_matrix_ivl.log ahb_matrix.vvp
   rm -fr ahb_matrix.vvp
else
   if [ -z "$test" ]; then echo -e "\n   Error: no 'test' specified."
   else                    echo -e "\n   Error: incorrect 'test' value - '${test}'."
   fi
   echo -e "   Info: valid 'test' values are : ahb | gen* | arbiter | ahb_demux | extender | apb_demux | ahb_bridge* | ahb2apb | 4k | matrix\n"
fi
