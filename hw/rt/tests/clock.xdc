# Clock Definition for aclk
# Frequency: 100 MHz => Period = 1 / 100MHz = 10 ns
# Duty Cycle: 50%
create_clock -period 10.0 -name aclk [get_ports clk]