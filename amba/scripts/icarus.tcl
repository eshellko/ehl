if [ "$test" == "matrix" ] ; then
   iverilog -D ICARUS -s ehl_ahb_matrix_tb src/rtl/ehl_ahb_matrix.v src/rtl/ehl_ahb_default_slave.v src/rtl/ehl_ahb_matrix_in.v src/rtl/ehl_ahb_matrix_out.v ../logic/src/rtl/ehl_arbiter.v src/fv/ehl_ahb_matrix_tb.v \
      -D __ehl_vcd__ \
      -I ../verification/src/fv/tasks -o ahb_matrix.vvp ; # src/rtl/ehl_axi_4kw.v src/rtl/ehl_axi_4kr.v
   vvp -l reports/ahb_matrix_ivl.log ahb_matrix.vvp
   rm -fr ahb_matrix.vvp
else
   if [ -z "$test" ]; then echo -e "\n   Error: no 'test' specified."
   else                    echo -e "\n   Error: incorrect 'test' value - '${test}'."
   fi
   echo -e "   Info: valid 'test' values are : matrix\n"
fi
