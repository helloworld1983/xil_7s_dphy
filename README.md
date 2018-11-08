D-PHY slave for Xilinx 7 series FPGA
==============================

This module is created to recieve high-speed signals from MIPI CSI-2 compatible devices.

It doesn't support LP communication. Only slave functionality is persistent.

IP core was created in educational purposes. Idea was taken from https://github.com/daveshah1/CSI2Rx

To buffer input clock and deserialize input data following Xilinx 7 series specific modules were used.

Clock lane PHY
--------------

**IBUFDS** - converts input differential clock to single-ended

**BUFIO** - passes D-PHY clock to clock distribution network

**BUFR** - divides incoming bit DDR clock by 4 to create byte clock

Data lane PHY
-------------

**IBUFDS** - converts input differential data to single-ended

**IDELAYE2** - delays input data to align it with clock

**IDELAYCTRL** - controls IDELAYE2

**ISERDESE2** - deserialize input data to bytes

If you want to use this module with other devices you need to replace them with appropriate ones.
