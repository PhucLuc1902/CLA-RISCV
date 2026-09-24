## ==========================================================
## SystemDemo constraints for Arty Z7-20
## btn[6:0]  - 6 on-board buttons/switches + 1 JA pin
## led[7:0]  - lower 4 bits shown on on-board LEDs
## ==========================================================

## Clock (needed by SystemDatapath; SystemDemo has no clk port so this
## constraint is simply ignored when SystemDemo is the active top).
set_property -dict { PACKAGE_PIN H16    IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk }];

## ----------------
## Switches -> btn
## ----------------
## SW0  (M20) -> btn[0]
set_property -dict { PACKAGE_PIN M20    IOSTANDARD LVCMOS33 } [get_ports { btn[0] }]; # SW0

## SW1  (M19) -> btn[1]
set_property -dict { PACKAGE_PIN M19    IOSTANDARD LVCMOS33 } [get_ports { btn[1] }]; # SW1

## ----------------
## Pushbuttons -> btn
## ----------------
## BTN0 (D19) -> btn[2]
set_property -dict { PACKAGE_PIN D19    IOSTANDARD LVCMOS33 } [get_ports { btn[2] }]; # BTN0

## BTN1 (D20) -> btn[3]
set_property -dict { PACKAGE_PIN D20    IOSTANDARD LVCMOS33 } [get_ports { btn[3] }]; # BTN1

## BTN2 (L20) -> btn[4]
set_property -dict { PACKAGE_PIN L20    IOSTANDARD LVCMOS33 } [get_ports { btn[4] }]; # BTN2

## BTN3 (L19) -> btn[5]
set_property -dict { PACKAGE_PIN L19    IOSTANDARD LVCMOS33 } [get_ports { btn[5] }]; # BTN3

## ----------------
## Extra input (JA1) -> btn[6]
## If you don't use it, it will just float; you can tie a wire/button here.
## ----------------
set_property -dict { PACKAGE_PIN Y18    IOSTANDARD LVCMOS33 } [get_ports { btn[6] }]; # JA1_P

## -----------
## LEDs -> led
## We only have 4 user LEDs, so we show sum[3:0] on them.
## led[7:4] will exist logically but are not constrained to pins.
## -----------
## LED0 (R14) -> led[0]
set_property -dict { PACKAGE_PIN R14    IOSTANDARD LVCMOS33 } [get_ports { led[0] }]; # LED0

## LED1 (P14) -> led[1]
set_property -dict { PACKAGE_PIN P14    IOSTANDARD LVCMOS33 } [get_ports { led[1] }]; # LED1

## LED2 (N16) -> led[2]
set_property -dict { PACKAGE_PIN N16    IOSTANDARD LVCMOS33 } [get_ports { led[2] }]; # LED2

## LED3 (M14) -> led[3]
set_property -dict { PACKAGE_PIN M14    IOSTANDARD LVCMOS33 } [get_ports { led[3] }]; # LED3

## RGB LED4 (Green Channel) -> led[4]
set_property -dict { PACKAGE_PIN G17    IOSTANDARD LVCMOS33 } [get_ports { led[4] }]; 

## RGB LED5 (Green Channel) -> led[5]
set_property -dict { PACKAGE_PIN L14    IOSTANDARD LVCMOS33 } [get_ports { led[5] }];
