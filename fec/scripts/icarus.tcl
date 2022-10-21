if [ "$test" == "crc" ] ; then
   iverilog -s ehl_crc_tb -o ehl_crc.vvp -I ../verification/src/fv/tasks -tvvp src/fv/ehl_crc_tb.v src/rtl/ehl_crc.v -I src/fv/ ../logic/src/rtl/ehl_reverse.v
#   vvp -l reports/ehl_crc.log ehl_crc.vvp
   vvp -l reports/ehl_crc.log ehl_crc.vvp +CRC8
   rm -f ehl_crc.vvp
elif [ "$test" == "ecc" ] ; then
   iverilog -I ../verification/src/fv/tasks -s ehl_ecc_tb -o ehl_ecc_tb.vvp -tvvp src/rtl/ehl_ecc.v src/fv/ehl_ecc_tb.v -P ehl_ecc_tb.WIDTH=8
   vvp -l reports/ehl_ecc_icarus.log ehl_ecc_tb.vvp
   rm -f ehl_ecc_tb.vvp

   iverilog -I ../verification/src/fv/tasks -s ehl_ecc_tb -o ehl_ecc_tb.vvp -tvvp src/rtl/ehl_ecc.v src/fv/ehl_ecc_tb.v -P ehl_ecc_tb.WIDTH=8 -P ehl_ecc_tb.SECDED=0
   vvp -l reports/ehl_ecc_sec_icarus.log ehl_ecc_tb.vvp
   rm -f ehl_ecc_tb.vvp
elif [ "$test" == "rs" ] ; then
   iverilog -D__pipeline -s ehl_rs_tb -o ehl_rs.vvp -tvvp -I ../verification/src/fv/tasks  -Isrc/rtl src/rtl/ehl_rs_dec.v src/rtl/ehl_rs_enc.v src/fv/ehl_rs_tb.v ../techmap/src/rtl/ehl_cdc.v
   vvp -l reports/ehl_rs.log ehl_rs.vvp
   rm -fr ehl_rs.vvp
elif [ "$test" == "netlist_ecc" ] ; then
   iverilog -D__NETLIST__ -I ../verification/src/fv/tasks -s ehl_ecc_tb -o ehl_ecc_tb.vvp -tvvp -D__NETLIST__ data/netlist2.v src/fv/ehl_ecc_tb.v -P ehl_ecc_tb.WIDTH=8
   vvp -l reports/ehl_ecc_icarus_netlist.log ehl_ecc_tb.vvp
   rm -f ehl_ecc_tb.vvp
else
   if [ -z "$test" ]; then echo -e "\n   Error: no 'test' specified."
   else                    echo -e "\n   Error: incorrect 'test' value - '${test}'."
   fi
   echo -e "   Info: valid 'test' values are : crc | ecc | rs | netlist_ecc\n"
fi
