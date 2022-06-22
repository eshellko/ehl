if [ "$test" == "ecc" ] ; then
   iverilog -I ../verification/src/fv/tasks -s ehl_ecc_tb -o ehl_ecc_tb.vvp -tvvp -D__mask128__ -D__reorder__ src/rtl/ehl_ecc.v src/fv/ehl_ecc_tb.v -P ehl_ecc_tb.WIDTH=8
   vvp -l reports/ehl_ecc_icarus.log ehl_ecc_tb.vvp
   rm -f ehl_ecc_tb.vvp

   iverilog -I ../verification/src/fv/tasks -s ehl_ecc_tb -o ehl_ecc_tb.vvp -tvvp -D__mask128__ -D__reorder__ src/rtl/ehl_ecc.v src/fv/ehl_ecc_tb.v -P ehl_ecc_tb.WIDTH=8 -P ehl_ecc_tb.SECDED=0
   vvp -l reports/ehl_ecc_sec_icarus.log ehl_ecc_tb.vvp
   rm -f ehl_ecc_tb.vvp
else
   if [ -z "$test" ]; then echo -e "\n   Error: no 'test' specified."
   else                    echo -e "\n   Error: incorrect 'test' value - '${test}'."
   fi
   echo -e "   Info: valid 'test' values are : ecc\n"
fi
