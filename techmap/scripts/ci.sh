#!/bin/sh

make --ignore-errors xrun ip=techmap test=spram
make --ignore-errors icarus ip=techmap test=clock_mux
make --ignore-errors icarus ip=techmap test=reset_sync
make --ignore-errors icarus ip=techmap test=techmap
make --ignore-errors icarus ip=techmap test=spram
