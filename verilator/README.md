
## SMSTang simulation suite

This directory contains a verilator-based RTL simulator for SMSTang.

You can run the simulation as follows,

```
make

hexdump -v -e '/1 "%02x\n"' rom.sms > rom.hex
# modify ../src/verilator/test_loader.v to load your .hex file

make sim
```

You can also get sound output with `make audio`.

Currently the verilog version of VM2413 is buggy. So FM simulation is not working.
However the actual core uses VHDL VM2413 and is fine.