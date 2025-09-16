transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

asim +access +r +m+soc_uart  -L xil_defaultlib -L xilinx_vip -L xpm -L lib_cdc_v1_0_3 -L proc_sys_reset_v5_0_16 -L microblaze_v11_0_14 -L microblaze_riscv_v1_0_3 -L lmb_v10_v3_0_14 -L lmb_bram_if_cntlr_v4_0_25 -L blk_mem_gen_v8_4_9 -L axi_lite_ipif_v3_0_4 -L mdm_riscv_v1_0_3 -L xlconstant_v1_1_9 -L smartconnect_v1_0 -L axi_infrastructure_v1_1_0 -L axi_register_slice_v2_1_33 -L axi_vip_v1_1_19 -L lib_pkg_v1_0_4 -L lib_srl_fifo_v1_0_4 -L axi_uartlite_v2_0_37 -L xilinx_vip -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.soc_uart xil_defaultlib.glbl

do {soc_uart.udo}

run 1000ns

endsim

quit -force
