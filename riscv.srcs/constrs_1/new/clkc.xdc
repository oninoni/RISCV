
create_generated_clock -name CLOCK_CPU -source [get_ports *CLK*] -divide_by 64 [get_pins {clk_divider_reg[5]/Q}]
create_generated_clock -name CLOCK_DEBOUNCE -source [get_ports *CLK*] -divide_by 65536 [get_pins {clk_divider_reg[15]/Q}]
