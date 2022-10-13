if [ "$test" == "techmap" ] ; then
   for i in buf dff or xor cdc clock_mux clock_div clock_gate ; do
      echo "   Info: test '${i}'."
      iverilog -I ../verification/src/fv/tasks -D__ehl_vcd__ -s map_${i}_tb src/rtl/ehl_stdcells.v src/fv/map_${i}_tb.v -P map_${i}_tb.TECHNOLOGY=0 \
         src/rtl/ehl_cdc.v src/rtl/ehl_clock_mux.v src/rtl/ehl_clock_div.v src/rtl/ehl_clock_gate.v
      vvp -l reports/${i}.log a.out
      rm -f a.out
   done
elif [ "$test" == "clock_mux" ] ; then
   puts "   Info: this test fails at the moment. As static MUX tested and not glitch free."
   iverilog -I ../verification/src/fv/tasks -D__ehl_vcd__ -s ehl_clock_mux_tb src/rtl/ehl_clock_mux.v src/fv/ehl_clock_mux_tb.v
   vvp -l reports/clock_mux.log a.out
   rm -f a.out
elif [ "$test" == "reset_sync" ] ; then
   iverilog -I ../verification/src/fv/tasks -D__ehl_vcd__ -s ehl_reset_sync_tb src/rtl/ehl_reset_sync.v src/fv/ehl_reset_sync_tb.v src/rtl/ehl_clock_gate.v
   vvp -l reports/reset_sync.log a.out
   rm -f a.out
elif [ "$test" == "spram" ] ; then
   iverilog -I ../verification/src/fv/tasks -D__ehl_vcd__ -s ehl_spram_tb src/rtl/ehl_spram.v src/fv/ehl_spram_tb.v
   vvp -l reports/spram.log a.out
   rm -f a.out
else
   if [ -z "$test" ]; then echo -e "\n   Error: no 'test' specified."
   else                    echo -e "\n   Error: incorrect 'test' value - '${test}'."
   fi
   echo -e "   Info: valid 'test' values are : techmap | clock_mux | reset_sync | spram\n"
fi
