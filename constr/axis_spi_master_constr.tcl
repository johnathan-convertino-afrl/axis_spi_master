# TCL script to create up_spi_ constraints for every instantiated core.

foreach instance [get_cells -hier -filter {ref_name==axis_spi_master || orig_ref_name==axis_spi_master}] {
  puts "INFO: Constraining $instance"

  set_property KEEP_HIERARCHY TRUE [get_cells $instance]
  
  # the fastest the clock can possibly be when generated is half of the original clock
  create_generated_clock -name fast_spi_clk -source [get_pins $instance/r_clk_o_reg/C] -divide_by 2 [get_nets $instance/sclk]
}
