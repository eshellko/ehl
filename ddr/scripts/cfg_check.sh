#!/bin/bash
#
# Note: if all required parameters not defined, then set them to invalid values
#       thus, there is no default parameters
#
if [ -z "$SDRAM_SPEED" ];     then export SDRAM_SPEED=DDR0_0; fi
if [ -z "$AXI_QUEUE_DEPTH" ]; then export AXI_QUEUE_DEPTH=0; fi
if [ -z "$DRAM_VENDOR" ];     then export DRAM_VENDOR=9; fi
if [ -z "$AXI_WIDTH" ];       then export AXI_WIDTH=4; fi
if [ -z "$SDRAM_WIDTH" ];     then export SDRAM_WIDTH=3; fi
if [ -z "$DENSITY" ];         then export DENSITY=1M; fi
if [ -z "$PHY_TYPE" ];        then export PHY_TYPE=9; fi
if [ -z "$SIM" ];             then export SIM=sim; fi
#
# Note: prepare temporary variables
#
SPEED=${SDRAM_SPEED:3:1}
#
# Note: exclude unsupported configurations
#       initially all of them treated as supported
#
VALID_CFG=1
#
# Note: exclude invalid parameters values
#
if [ "$SDRAM_SPEED" != "DDR2_250" ] && [ "$SDRAM_SPEED" != "DDR2_400" ] && [ "$SDRAM_SPEED" != "DDR2_533" ] && [ "$SDRAM_SPEED" != "DDR2_667" ] && [ "$SDRAM_SPEED" != "DDR2_800" ] && [ "$SDRAM_SPEED" != "DDR3_600" ]&& [ "$SDRAM_SPEED" != "DDR3_800" ] && [ "$SDRAM_SPEED" != "DDR3_1066" ] && [ "$SDRAM_SPEED" != "DDR3_1333" ] && [ "$SDRAM_SPEED" != "DDR3_1600" ] && [ "$SDRAM_SPEED" != "DDR4_1600" ] && [ "$SDRAM_SPEED" != "DDR4_1866" ] && [ "$SDRAM_SPEED" != "DDR4_2133" ] && [ "$SDRAM_SPEED" != "DDR4_2400" ] && [ "$SDRAM_SPEED" != "DDR4_2666" ] && [ "$SDRAM_SPEED" != "DDR4_2933" ] && [ "$SDRAM_SPEED" != "DDR4_3200" ] ; then VALID_CFG=0; fi
if [ "$AXI_QUEUE_DEPTH" != "2" ] && [ "$AXI_QUEUE_DEPTH" != "4" ] ; then VALID_CFG=0; fi
if [ "$DRAM_VENDOR" != "1" ] && [ "$DRAM_VENDOR" != "2" ] && [ "$DRAM_VENDOR" != "3" ] && [ "$DRAM_VENDOR" != "4" ]  ; then VALID_CFG=0; fi
if [ "$AXI_WIDTH" != "32" ] && [ "$AXI_WIDTH" != "64" ] && [ "$AXI_WIDTH" != "128" ]  ; then VALID_CFG=0; fi
if [ "$DENSITY" != "256M" ] && [ "$DENSITY" != "512M" ] && [ "$DENSITY" != "1G" ] && [ "$DENSITY" != "2G" ] && [ "$DENSITY" != "4G" ] && [ "$DENSITY" != "8G" ] && [ "$DENSITY" != "16G" ] ; then VALID_CFG=0; fi
if [ "$PHY_TYPE" != "0" ] && [ "$PHY_TYPE" != "1" ] && [ "$PHY_TYPE" != "2" ] && [ "$PHY_TYPE" != "3" ] && [ "$PHY_TYPE" != "4" ] && [ "$PHY_TYPE" != "5" ] && [ "$PHY_TYPE" != "6" ]  ; then VALID_CFG=0; fi
if [ "$SIM" != "icarus" ] && [ "$SIM" != "ius" ] && [ "$SIM" != "vcs" ] && [ "$SIM" != "questa" ] ; then VALID_CFG=0; fi
#
# AXI to SDRAM ratio is limited to 2, 4, 8
# Q: why 128/8 is not supported, as 16 ratio is OKAY, isn't it!?
#
if [ $(($AXI_WIDTH/$SDRAM_WIDTH)) != 2 ] && [ $(($AXI_WIDTH/$SDRAM_WIDTH)) != 4 ] && [ $(($AXI_WIDTH/$SDRAM_WIDTH)) != 8 ] ; then VALID_CFG=0; fi
#
# Note: there is no plain-text DDR4 models
#
if [ "$SIM" = "icarus" ] && [ "$SPEED" = "4" ] ; then VALID_CFG=0; fi
#
# Note: AXI_QUEUE_DEPTH gives almost same result so exclude some configurations based on DRAM_VENDOR
#
if ( [ "$AXI_QUEUE_DEPTH" = "2" ] && ( [ "$DRAM_VENDOR" = "1" ] || [ "$DRAM_VENDOR" = "2" ] ) ) ; then VALID_CFG=0; fi
if ( [ "$AXI_QUEUE_DEPTH" = "4" ] && ( [ "$DRAM_VENDOR" = "3" ] || [ "$DRAM_VENDOR" = "4" ] ) ) ; then VALID_CFG=0; fi
#
# Note: 'ehl_ddr_phy' does not support DDR3
# Note: PHY-1 does not support DDR4
# Note: PHY-2 does not support DDR2/4
# Note: PHY-3 does not support DDR2
# Note: PHY-4/5 does not support DDR3/4
# Note: PHY-6 does not support DDR4
#
if [ "$PHY_TYPE" = "0" ] && [ "$SPEED" = "3" ] ; then VALID_CFG=0; fi
if [ "$PHY_TYPE" = "1" ] && [ "$SPEED" = "4" ] ; then VALID_CFG=0; fi
if [ "$PHY_TYPE" = "2" ] && [ "$SPEED" != "3" ] ; then VALID_CFG=0; fi
if [ "$PHY_TYPE" = "3" ] && [ "$SPEED" = "2" ] ; then VALID_CFG=0; fi
if [ "$PHY_TYPE" = "4" ] && [ "$SPEED" != "2" ] ; then VALID_CFG=0; fi
if [ "$PHY_TYPE" = "5" ] && [ "$SPEED" != "2" ] ; then VALID_CFG=0; fi
if [ "$PHY_TYPE" = "6" ] && [ "$SPEED" = "4" ] ; then VALID_CFG=0; fi
#
# Note: icarus does not suppoort encrypted PHY
#
if [ "$PHY_TYPE" = "5" ] && [ "$SIM" = "icarus" ] ; then VALID_CFG=0; fi
if [ "$PHY_TYPE" = "2" ] && [ "$SIM" = "icarus" ] ; then VALID_CFG=0; fi
#
# Note: 8G Hynix is too large during elaboration... 16G probably too... || [ $DENSITY = "8G" ] ;
#
if [ "$DRAM_VENDOR" = "2" ] && ( [ "$DENSITY" = "8G" ] || [ "$DENSITY" = "16G" ] ) ; then VALID_CFG=0; fi
#
# Note: dnesities limited by DDR generation
#
if [ "$SPEED" = "2" ] && ( [ "$DENSITY" = "4G" ] || [ "$DENSITY" = "8G" ] || [ "$DENSITY" = "16G" ] ) ; then VALID_CFG=0; fi
if [ "$SPEED" = "3" ] && ( [ "$DENSITY" = "8G" ] || [ "$DENSITY" = "16G" ] ) ; then VALID_CFG=0; fi
#
# Note: DDR3_2133 not supported by Micron memory model so far...
#
if [ "$DRAM_VENDOR" = "1" ] && [ "$SDRAM_SPEED" = "DDR3_2133" ] ; then VALID_CFG=0; fi
#
# Note: PHY-1 states that DDR3 SDRAM memories up to 1066 Mbps data rates are supported
#       although 1333 and 1600 also pass tests, while DDR3_1866 cause training failure
#
if [ "$PHY_TYPE" = "1" ] && ( [ "$SDRAM_SPEED" = "DDR3_1333" ] || [ "$SDRAM_SPEED" = "DDR3_1600" ] || [ "$SDRAM_SPEED" = "DDR3_1866" ] ) ; then VALID_CFG=0; fi


#       # Note: PHY=0 ;
#       if [ "$PHY_TYPE" = 0 ] ; then
#          if [ "$SDRAM_SPEED" = "DDR2_250" ] || [ "$SDRAM_SPEED" = "DDR2_400" ] || [ "$SDRAM_SPEED" = "DDR2_533" ] || [ "$SDRAM_SPEED" = "DDR2_667" ] || [ "$SDRAM_SPEED" = "DDR2_800" ] ; then
#             if [ "$DRAM_VENDOR" = "1" ] && ( [ "$DENSITY" = "256M" ] || [ "$DENSITY" = "512M" ] || [ "$DENSITY" = "1G" ] || [ "$DENSITY" = "2G" ] ) ; then
#                VALID_CFG=1 ;
#             fi ;
#             if [ "$SIM" = ius ] && [ "$DRAM_VENDOR" = "3" ] && [ "$DENSITY" = "4G" ] && [ "$SDRAM_SPEED" = "DDR2_800" ] ; then
#                VALID_CFG=1 ;
#             fi ;
#             if [ "$SIM" = ius ] && [ "$DRAM_VENDOR" = "4" ] && [ "$DENSITY" = "512M" ] && ( [ "$SDRAM_SPEED" = "DDR2_800" ] || [ "$SDRAM_SPEED" = "DDR2_667" ] ) ; then
#                VALID_CFG=1 ;
#             fi ;
#          elif [ "$SIM" = ius ] && ( [ "$SDRAM_SPEED" = "DDR4_1600" ] || [ "$SDRAM_SPEED" = "DDR4_1866" ] || [ "$SDRAM_SPEED" = "DDR4_2133" ] || [ "$SDRAM_SPEED" = "DDR4_2400" ] || [ "$SDRAM_SPEED" = "DDR4_2666" ] || [ "$SDRAM_SPEED" = "DDR4_2933" ] || [ "$SDRAM_SPEED" = "DDR4_3200" ] ) ; then
#             if [ "$DRAM_VENDOR" = "1" ] && ( [ "$DENSITY" = "2G" ] || [ "$DENSITY" = "4G" ] || [ "$DENSITY" = "8G" ] || [ "$DENSITY" = "16G" ] ) ; then
#                VALID_CFG=1 ;
#             fi ;
#             if [ "$SIM" = ius ] && [ "$DRAM_VENDOR" = "3" ] && [ "$DENSITY" = "4G" ] && [ "$SDRAM_SPEED" = "DDR4_800" ] ; then
#                VALID_CFG=1 ;
#             fi ;
#          fi ;
#       # Note: PHY=1 ;
#       elif [ "$PHY_TYPE" = 1 ] ; then
#          if [ "$SIM" = ius ] && ( [ "$SDRAM_SPEED" = "DDR3_800" ] || [ "$SDRAM_SPEED" = "DDR3_1066" ] ) ; then
#             if [ "$DRAM_VENDOR" = "1" ] && ( [ "$DENSITY" = "1G" ] || [ "$DENSITY" = "2G" ] || [ "$DENSITY" = "4G" ] || [ "$DENSITY" = "8G" ] ) ; then
#                VALID_CFG=1 ;
#             fi ;
#             if [ "$SIM" = ius ] && [ "$DRAM_VENDOR" = "3" ] && [ "$DENSITY" = "4G" ] && [ "$SDRAM_SPEED" = "DDR3_800" ] ; then
#                VALID_CFG=1 ;
#             fi ;
#          elif [ "$SIM" != icarus ] && ( [ "$SDRAM_SPEED" = "DDR2_250" ] || [ "$SDRAM_SPEED" = "DDR2_400" ] || [ "$SDRAM_SPEED" = "DDR2_533" ] || [ "$SDRAM_SPEED" = "DDR2_667" ] || [ "$SDRAM_SPEED" = "DDR2_800" ] ) ; then
#             if [ "$DRAM_VENDOR" = "1" ] && ( [ "$DENSITY" = "256M" ] || [ "$DENSITY" = "512M" ] || [ "$DENSITY" = "1G" ] || [ "$DENSITY" = "2G" ] ) ; then
#                VALID_CFG=1 ;
#             fi ;
#             if [ "$SIM" = ius ] && [ "$DRAM_VENDOR" = "3" ] && [ "$DENSITY" = "4G" ] && [ "$SDRAM_SPEED" = "DDR2_800" ] ; then
#                VALID_CFG=1 ;
#             fi ;
#             if [ "$SIM" = ius ] && [ "$DRAM_VENDOR" = "4" ] && [ "$DENSITY" = "512M" ] && ( [ "$SDRAM_SPEED" = "DDR2_800" ] || [ "$SDRAM_SPEED" = "DDR2_667" ] ) ; then
#                VALID_CFG=1 ;
#             fi ;
#          fi ;
#       # Note: PHY=2 ;
#       elif [ "$PHY_TYPE" = 2 ] ; then
#          if [[ "$SDRAM_SPEED" = "DDR3_600" && "$SDRAM_WIDTH" = 32 && "$ECC_ENA" = 0 ]] ; then
#             if [ "$DRAM_VENDOR" = "1" ] && ( [ "$DENSITY" = "1G" ] || [ "$DENSITY" = "2G" ] || [ "$DENSITY" = "4G" ] || [ "$DENSITY" = "8G" ] ) ; then
#                VALID_CFG=1 ;
#             fi ;
#             if [ "$SIM" = ius ] && [ "$DRAM_VENDOR" = "3" ] && [ "$DENSITY" = "4G" ] && [ "$SDRAM_SPEED" = "DDR3_800" ] ; then
#                VALID_CFG=1 ;
#             fi ;
#          fi;
#          if [ "$SDRAM_SPEED" = "DDR3_800" ] || [ "$SDRAM_SPEED" = "DDR3_1066" ] || [ "$SDRAM_SPEED" = "DDR3_1333" ] || [ "$SDRAM_SPEED" = "DDR3_1600" ] ; then
#             if [ "$DRAM_VENDOR" = "1" ] && ( [ "$DENSITY" = "1G" ] || [ "$DENSITY" = "2G" ] || [ "$DENSITY" = "4G" ] || [ "$DENSITY" = "8G" ] ) ; then
#                VALID_CFG=1 ;
#             fi ;
#             if [ "$SIM" = ius ] && [ "$DRAM_VENDOR" = "3" ] && [ "$DENSITY" = "4G" ] && [ "$SDRAM_SPEED" = "DDR3_800" ] ; then
#                VALID_CFG=1 ;
#             fi ;
#          fi ;
#       # Note: PHY=3 ;
#       elif [ "$PHY_TYPE" = 3 ] ; then
#          if [ "$SIM" = ius ] && ( [ "$SDRAM_SPEED" = "DDR3_800" ] || [ "$SDRAM_SPEED" = "DDR3_1066" ] || [ "$SDRAM_SPEED" = "DDR3_1333" ] || [ "$SDRAM_SPEED" = "DDR3_1600" ] ) ; then
#             if [ "$DRAM_VENDOR" = "1" ] && ( [ "$DENSITY" = "1G" ] || [ "$DENSITY" = "2G" ] || [ "$DENSITY" = "4G" ] || [ "$DENSITY" = "8G" ] ) ; then
#                VALID_CFG=1 ;
#             fi ;
#             if [ "$SIM" = ius ] && [ "$DRAM_VENDOR" = "3" ] && [ "$DENSITY" = "4G" ] && [ "$SDRAM_SPEED" = "DDR3_800" ] ; then
#                VALID_CFG=1 ;
#             fi ;
#          elif [ "$SIM" = ius ] && ( [ "$SDRAM_SPEED" = "DDR4_1600" ] || [ "$SDRAM_SPEED" = "DDR4_1866" ] || [ "$SDRAM_SPEED" = "DDR4_2133" ] || [ "$SDRAM_SPEED" = "DDR4_2400" ] || [ "$SDRAM_SPEED" = "DDR4_2666" ] || [ "$SDRAM_SPEED" = "DDR4_2933" ] || [ "$SDRAM_SPEED" = "DDR4_3200" ] ) ; then
#             if [ "$DRAM_VENDOR" = "1" ] && ( [ "$DENSITY" = "2G" ] || [ "$DENSITY" = "4G" ] || [ "$DENSITY" = "8G" ] || [ "$DENSITY" = "16G" ] ) ; then
#                VALID_CFG=1 ;
#             fi ;
#             if [ "$SIM" = ius ] && [ "$DRAM_VENDOR" = "3" ] && [ "$DENSITY" = "4G" ] && [ "$SDRAM_SPEED" = "DDR4_800" ] ; then
#                VALID_CFG=1 ;
#             fi ;
#          fi ;
#       # Note: PHY=4;
#       elif [ "$PHY_TYPE" = 4 ] && [ "$SIM" = ius ] ; then
#          if [ "$SDRAM_SPEED" = "DDR2_250" ] || [ "$SDRAM_SPEED" = "DDR2_400" ] || [ "$SDRAM_SPEED" = "DDR2_533" ] || [ "$SDRAM_SPEED" = "DDR2_667" ] || [ "$SDRAM_SPEED" = "DDR2_800" ] ; then
# # TODO: Q: what expreesion?
#             if [ $(($SDRAM_WIDTH+$ECC_ENA)) = 16 ] || [ $(($SDRAM_WIDTH+$ECC_ENA)) = 9 ] ; then
#                if [ "$DRAM_VENDOR" = "1" ] && ( [ "$DENSITY" = "256M" ] || [ "$DENSITY" = "512M" ] || [ "$DENSITY" = "1G" ] || [ "$DENSITY" = "2G" ] ) ; then
#                   VALID_CFG=1 ;
#                fi ;
#                if [ "$SIM" = ius ] && [ "$DRAM_VENDOR" = "3" ] && [ "$DENSITY" = "4G" ] && [ "$SDRAM_SPEED" = "DDR2_800" ] ; then
#                   VALID_CFG=1 ;
#                fi ;
#                if [ "$SIM" = ius ] && [ "$DRAM_VENDOR" = "4" ] && [ "$DENSITY" = "512M" ] && ( [ "$SDRAM_SPEED" = "DDR2_800" ] || [ "$SDRAM_SPEED" = "DDR2_667" ] ) ; then
#                   VALID_CFG=1 ;
#                fi ;
#             fi ;
#          fi ;
#       # Note: PHY=5 ;
#       elif [ "$PHY_TYPE" = 5 ] ; then
#          if [ "$SDRAM_SPEED" = "DDR2_250" ] || [ "$SDRAM_SPEED" = "DDR2_400" ] || [ "$SDRAM_SPEED" = "DDR2_533" ] || [ "$SDRAM_SPEED" = "DDR2_667" ] ; then
# # TODO: Q: what expreesion?
#             if [ $(($SDRAM_WIDTH+$ECC_ENA)) = 8 ] || [ $(($SDRAM_WIDTH+$ECC_ENA)) = 16 ] || [ $(($SDRAM_WIDTH+$ECC_ENA)) = 32 ]|| [ $(($SDRAM_WIDTH+$ECC_ENA)) = 64 ]|| [ $(($SDRAM_WIDTH+$ECC_ENA)) = 72 ]   ; then
#                if [ "$DRAM_VENDOR" = "1" ] && ( [ "$DENSITY" = "256M" ] || [ "$DENSITY" = "512M" ] || [ "$DENSITY" = "1G" ] || [ "$DENSITY" = "2G" ] ) ; then
#                   VALID_CFG=1 ;
#                fi ;
#                if [ "$SIM" = ius ] && [ "$DRAM_VENDOR" = "3" ] && [ "$DENSITY" = "4G" ] && [ "$SDRAM_SPEED" = "DDR2_800" ] ; then
#                   VALID_CFG=1 ;
#                fi ;
#                if [ "$SIM" = ius ] && [ "$DRAM_VENDOR" = "4" ] && [ "$DENSITY" = "512M" ] && ( [ "$SDRAM_SPEED" = "DDR2_800" ] || [ "$SDRAM_SPEED" = "DDR2_667" ] ) ; then
#                   VALID_CFG=1 ;
#                fi ;
#             fi ;
#          fi ;
#       # Note: PHY=6 ;
#       #       DDR2/3 ;
#       # TODO: for RAMs define if DDR3_1866 can be supported ;
#       elif [ "$PHY_TYPE" = 6 ] ; then
#          if [ "$SIM" = ius ] && ( [ "$SDRAM_SPEED" = "DDR3_800" ] || [ "$SDRAM_SPEED" = "DDR3_1066" ] || [ "$SDRAM_SPEED" = "DDR3_1333" ] || [ "$SDRAM_SPEED" = "DDR3_1600" ] ) ; then
#             if [ "$DRAM_VENDOR" = "1" ] && ( [ "$DENSITY" = "1G" ] || [ "$DENSITY" = "2G" ] || [ "$DENSITY" = "4G" ] || [ "$DENSITY" = "8G" ] ) ; then
#                VALID_CFG=1 ;
#             fi ;
#             if [ "$SIM" = ius ] && [ "$DRAM_VENDOR" = "3" ] && [ "$DENSITY" = "4G" ] && [ "$SDRAM_SPEED" = "DDR3_800" ] ; then
#                VALID_CFG=1 ;
#             fi ;
#          elif [ "$SIM" != icarus ] && ( [ "$SDRAM_SPEED" = "DDR2_533" ] || [ "$SDRAM_SPEED" = "DDR2_667" ] || [ "$SDRAM_SPEED" = "DDR2_800" ] ) ; then
#             if [ "$DRAM_VENDOR" = "1" ] && ( [ "$DENSITY" = "256M" ] || [ "$DENSITY" = "512M" ] || [ "$DENSITY" = "1G" ] || [ "$DENSITY" = "2G" ] ) ; then
#                VALID_CFG=1 ;
#             fi ;
#             if [ "$SIM" = ius ] && [ "$DRAM_VENDOR" = "3" ] && [ "$DENSITY" = "4G" ] && [ "$SDRAM_SPEED" = "DDR2_800" ] ; then
#                VALID_CFG=1 ;
#             fi ;
#             if [ "$SIM" = ius ] && [ "$DRAM_VENDOR" = "4" ] && [ "$DENSITY" = "512M" ] && ( [ "$SDRAM_SPEED" = "DDR2_800" ] || [ "$SDRAM_SPEED" = "DDR2_667" ] ) ; then
#                VALID_CFG=1 ;
#             fi ;
#          fi ;
#       fi ;

#  echo "   Configuration: $AXI_WIDTH/$AXI_QUEUE_DEPTH $SDRAM_SPEED x $SDRAM_WIDTH @$DRAM_VENDOR ($DENSITY) with $PHY_TYPE using $SIM: is $VALID_CFG"

if [ "$VALID_CFG" = "0" ] ; then
   echo "   Error: unsupported configuration (APPL: $AXI_WIDTH/$AXI_QUEUE_DEPTH) (SPEED: $SDRAM_SPEED x $SDRAM_WIDTH) (RAM: $DRAM_VENDOR ($DENSITY)) (PHY: $PHY_TYPE) using $SIM."
   exit 1
fi
