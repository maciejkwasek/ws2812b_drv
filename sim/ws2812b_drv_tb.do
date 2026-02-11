vlib work
vmap work work

vcom ../../rtl/ws2812b_drv.vhd
vcom ../../tb/ws2812b_drv_tb.vhd

vsim ws2812b_drv_tb

add wave *
add wave /ws2812b_drv_inst/*

run 50 us
