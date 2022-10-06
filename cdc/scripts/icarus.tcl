if [ "$test" == "fifo" ] ; then

   for WIDTH_DIN_VALUE in 8 16 32; do
   for WIDTH_DOUT_VALUE in 8 16 32; do
   for DEPTH_VALUE in 8 4; do
   for SYNC_STAGE_VALUE in 2 3; do
   for DPRAM in 0 1; do
      iverilog \
         -P ehl_fifo_tb.WIDTH_DIN=${WIDTH_DIN_VALUE} \
         -P ehl_fifo_tb.WIDTH_DOUT=${WIDTH_DOUT_VALUE} \
         -P ehl_fifo_tb.DEPTH=${DEPTH_VALUE} \
         -P ehl_fifo_tb.USE_DPRAM=${DPRAM} \
         -P ehl_fifo_tb.SYNC_STAGE=${SYNC_STAGE_VALUE} \
         -D __ehl_vcd__UNUSED \
         -I ../verification/src/fv/tasks -g2005 -s ehl_fifo_tb -o data/ehl_fifo_tb.vvp -tvvp src/fv/ehl_fifo_tb.v ../techmap/src/rtl/ehl_cdc.v src/rtl/ehl_fifo.v src/rtl/ehl_fifo_rc.v src/rtl/ehl_fifo_wc.v src/rtl/ehl_gray_cnt.v \
         ../techmap/src/rtl/ehl_spram.v ../techmap/src/rtl/ehl_dpram.v \
         ../logic/src/rtl/ehl_bin2gray.v ../logic/src/rtl/ehl_gray2bin.v
      vvp -n -l reports/ehl_fifo_tb_${WIDTH_DIN_VALUE}_${WIDTH_DOUT_VALUE}_${DEPTH_VALUE}_${SYNC_STAGE_VALUE}_${DPRAM}.log data/ehl_fifo_tb.vvp
      rm -f data/ehl_fifo_tb.vvp
   done
   done
   done
   done
   done
elif [ "$test" == "gray" ] ; then
   iverilog -I ../verification/src/fv/tasks -D__ehl_vcd__ -s ehl_gray_cnt_tb src/rtl/ehl_gray_cnt.v src/fv/ehl_gray_cnt_tb.v
   vvp -l reports/gray_ivl.log a.out
   rm -f a.out
elif [ "$test" == "clk_ctrl" ] ; then
   iverilog -I ../verification/src/fv/tasks -D__ehl_vcd__ -s ehl_clk_ctrl_tb src/rtl/ehl_clk_ctrl.v src/fv/ehl_clk_ctrl_tb.v \
      ../techmap/src/rtl/ehl_cdc.v ../techmap/src/rtl/ehl_clock_gate.v
   vvp -l reports/clk_ctrl_ivl.log a.out
   rm -f a.out
elif [ "$test" == "fpga_cdc" ] ; then
   iverilog -I ../verification/src/fv/tasks -D__ehl_vcd__ -s ehl_cdc_tb data/simulation/modelsim/ehl_cdc.vo src/fv/ehl_cdc_tb.v \
      ../library/altera/quartus/18.0/sim_lib/cyclonev_atoms.v
   vvp -l reports/cdc_ivl.log a.out
   rm -f a.out
elif [ "$test" == "sc_fifo" ] ; then
   iverilog -I ../verification/src/fv/tasks -D__ehl_vcd__ -s ehl_sc_fifo_tb src/rtl/ehl_sc_fifo.v src/fv/ehl_sc_fifo_tb.v ../techmap/src/rtl/ehl_spram.v
   vvp -l reports/sc_fifo_ivl.log a.out
   rm -f a.out

   for WIDTH_DIN_VALUE in $(seq 8 64); do
      echo ${WIDTH_DIN_VALUE}
      iverilog -I ../verification/src/fv/tasks -D__ehl_vcd__ -s ehl_sc_fifo_tb src/rtl/ehl_sc_fifo.v src/fv/ehl_sc_fifo_tb.v ../techmap/src/rtl/ehl_spram.v ../fec/src/rtl/ehl_ecc.v -P ehl_sc_fifo_tb.ECC_ENA=1 -P ehl_sc_fifo_tb.WIDTH=${WIDTH_DIN_VALUE}
      vvp -l reports/sc_fifo_sec${WIDTH_DIN_VALUE}_ivl.log a.out
      rm -f a.out
   done
elif [ "$test" == "cmu" ] ; then
   iverilog -g2012 -DICARUS -I ../verification/src/fv/tasks -I src/fv -D__ehl_vcd__ -s ehl_cmu_tb src/fv/ehl_cmu_tb.v src/rtl/ehl_cmu.v src/rtl/ehl_clk_ctrl.v src/rtl/ehl_lbcd.v ../techmap/src/rtl/ehl_cdc.v ../techmap/src/rtl/ehl_clock_gate.v src/rtl/ehl_cdc_level.v
   vvp -n -l reports/cmu_ivl.log a.out
   rm -f a.out
else
   if [ -z "$test" ]; then echo -e "\n   Error: no 'test' specified."
   else                    echo -e "\n   Error: incorrect 'test' value - '${test}'."
   fi
   echo -e "   Info: valid 'test' values are : clk_ctrl | fifo | gray | fpga_cdc | sc_fifo | cmu\n"
fi
