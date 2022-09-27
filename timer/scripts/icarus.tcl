if [ "$test" == "timer" ] ; then
   # TODO: -P ehl_timer_tb.BUS_WIDTH=8    -P ehl_timer_tb.BUS_WIDTH=32
#   iverilog-vpi  -mingw=e:/Data/Cygwin -ivl=c:/iverilog010  ../share/src/fv/vpi/report_uninitialized.c
   iverilog -D ICARUS -g2012 -D __ehl_vcd__ -I ../verification/src/fv/tasks -I src/fv/timer -s ehl_timer_tb -o ehl_timer.vvp -tvvp src/fv/ehl_timer_tb.v -f scripts/timer.f \
      -P ehl_timer_tb.BUS_WIDTH=8
#   vvp -M. -mreport_uninitialized -l reports/ehl_timer.log ehl_timer.vvp
   vvp -l reports/ehl_timer.log ehl_timer.vvp +EHLTIMER_ALL
   rm -f ehl_timer.vvp
elif [ "$test" == "wdt" ] ; then
   for WIDTH in 8 16 32 ; do \
      iverilog -D ICARUS -g2012 -D __ehl_vcd__UNUSED -I ../verification/src/fv/tasks -I src/fv/wdt -s ehl_wdt_tb -o ehl_wdt.vvp -tvvp src/fv/ehl_wdt_tb.v \
         -P ehl_wdt_tb.WIDTH=${WIDTH} src/rtl/wdt/ehl_wdt.v
      vvp -l reports/ehl_wdt${WIDTH}.log ehl_wdt.vvp
      rm -f ehl_wdt.vvp
   done
else 
   if [ -z "$test" ]; then echo -e "\n   Error: no 'test' specified."
   else                    echo -e "\n   Error: incorrect 'test' value - '${test}'."
   fi
   echo -e "   Info: valid 'test' values are : timer | wdt\n"
fi
