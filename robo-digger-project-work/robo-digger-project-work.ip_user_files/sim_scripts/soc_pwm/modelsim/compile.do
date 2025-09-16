vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/lib_cdc_v1_0_3
vlib modelsim_lib/msim/proc_sys_reset_v5_0_16
vlib modelsim_lib/msim/xil_defaultlib
vlib modelsim_lib/msim/microblaze_v11_0_14
vlib modelsim_lib/msim/microblaze_riscv_v1_0_3
vlib modelsim_lib/msim/lmb_v10_v3_0_14
vlib modelsim_lib/msim/lmb_bram_if_cntlr_v4_0_25
vlib modelsim_lib/msim/blk_mem_gen_v8_4_9
vlib modelsim_lib/msim/generic_baseblocks_v2_1_2
vlib modelsim_lib/msim/axi_infrastructure_v1_1_0
vlib modelsim_lib/msim/axi_register_slice_v2_1_33
vlib modelsim_lib/msim/fifo_generator_v13_2_11
vlib modelsim_lib/msim/axi_data_fifo_v2_1_32
vlib modelsim_lib/msim/axi_crossbar_v2_1_34
vlib modelsim_lib/msim/axi_lite_ipif_v3_0_4
vlib modelsim_lib/msim/axi_intc_v4_1_20
vlib modelsim_lib/msim/xlconcat_v2_1_6
vlib modelsim_lib/msim/mdm_riscv_v1_0_3
vlib modelsim_lib/msim/lib_pkg_v1_0_4
vlib modelsim_lib/msim/lib_srl_fifo_v1_0_4
vlib modelsim_lib/msim/axi_uartlite_v2_0_37

vmap lib_cdc_v1_0_3 modelsim_lib/msim/lib_cdc_v1_0_3
vmap proc_sys_reset_v5_0_16 modelsim_lib/msim/proc_sys_reset_v5_0_16
vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib
vmap microblaze_v11_0_14 modelsim_lib/msim/microblaze_v11_0_14
vmap microblaze_riscv_v1_0_3 modelsim_lib/msim/microblaze_riscv_v1_0_3
vmap lmb_v10_v3_0_14 modelsim_lib/msim/lmb_v10_v3_0_14
vmap lmb_bram_if_cntlr_v4_0_25 modelsim_lib/msim/lmb_bram_if_cntlr_v4_0_25
vmap blk_mem_gen_v8_4_9 modelsim_lib/msim/blk_mem_gen_v8_4_9
vmap generic_baseblocks_v2_1_2 modelsim_lib/msim/generic_baseblocks_v2_1_2
vmap axi_infrastructure_v1_1_0 modelsim_lib/msim/axi_infrastructure_v1_1_0
vmap axi_register_slice_v2_1_33 modelsim_lib/msim/axi_register_slice_v2_1_33
vmap fifo_generator_v13_2_11 modelsim_lib/msim/fifo_generator_v13_2_11
vmap axi_data_fifo_v2_1_32 modelsim_lib/msim/axi_data_fifo_v2_1_32
vmap axi_crossbar_v2_1_34 modelsim_lib/msim/axi_crossbar_v2_1_34
vmap axi_lite_ipif_v3_0_4 modelsim_lib/msim/axi_lite_ipif_v3_0_4
vmap axi_intc_v4_1_20 modelsim_lib/msim/axi_intc_v4_1_20
vmap xlconcat_v2_1_6 modelsim_lib/msim/xlconcat_v2_1_6
vmap mdm_riscv_v1_0_3 modelsim_lib/msim/mdm_riscv_v1_0_3
vmap lib_pkg_v1_0_4 modelsim_lib/msim/lib_pkg_v1_0_4
vmap lib_srl_fifo_v1_0_4 modelsim_lib/msim/lib_srl_fifo_v1_0_4
vmap axi_uartlite_v2_0_37 modelsim_lib/msim/axi_uartlite_v2_0_37

vcom -work lib_cdc_v1_0_3 -64 -93  \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/2a4f/hdl/lib_cdc_v1_0_rfs.vhd" \

vcom -work proc_sys_reset_v5_0_16 -64 -93  \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/0831/hdl/proc_sys_reset_v5_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -64 -93  \
"../../../bd/soc_pwm/ip/soc_pwm_proc_sys_reset_0_0/sim/soc_pwm_proc_sys_reset_0_0.vhd" \

vlog -work xil_defaultlib -64 -incr -mfcu  "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/3cbc" "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/ec67/hdl" \
"../../../bd/soc_pwm/ip/soc_pwm_clk_wiz_0/soc_pwm_clk_wiz_0_clk_wiz.v" \
"../../../bd/soc_pwm/ip/soc_pwm_clk_wiz_0/soc_pwm_clk_wiz_0.v" \

vcom -work microblaze_v11_0_14 -64 -93  \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/a243/hdl/microblaze_v11_0_vh_rfs.vhd" \

vcom -work microblaze_riscv_v1_0_3 -64 -93  \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/f9dd/hdl/microblaze_riscv_v1_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -64 -93  \
"../../../bd/soc_pwm/ip/soc_pwm_microblaze_riscv_0_0/sim/soc_pwm_microblaze_riscv_0_0.vhd" \

vcom -work lmb_v10_v3_0_14 -64 -93  \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/7495/hdl/lmb_v10_v3_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -64 -93  \
"../../../bd/soc_pwm/ip/soc_pwm_dlmb_v10_0/sim/soc_pwm_dlmb_v10_0.vhd" \
"../../../bd/soc_pwm/ip/soc_pwm_ilmb_v10_0/sim/soc_pwm_ilmb_v10_0.vhd" \

vcom -work lmb_bram_if_cntlr_v4_0_25 -64 -93  \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/73e9/hdl/lmb_bram_if_cntlr_v4_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -64 -93  \
"../../../bd/soc_pwm/ip/soc_pwm_dlmb_bram_if_cntlr_0/sim/soc_pwm_dlmb_bram_if_cntlr_0.vhd" \
"../../../bd/soc_pwm/ip/soc_pwm_ilmb_bram_if_cntlr_0/sim/soc_pwm_ilmb_bram_if_cntlr_0.vhd" \

vlog -work blk_mem_gen_v8_4_9 -64 -incr -mfcu  "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/3cbc" "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/ec67/hdl" \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/5ec1/simulation/blk_mem_gen_v8_4.v" \

vlog -work xil_defaultlib -64 -incr -mfcu  "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/3cbc" "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/ec67/hdl" \
"../../../bd/soc_pwm/ip/soc_pwm_lmb_bram_0/sim/soc_pwm_lmb_bram_0.v" \

vlog -work generic_baseblocks_v2_1_2 -64 -incr -mfcu  "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/3cbc" "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/ec67/hdl" \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/0c28/hdl/generic_baseblocks_v2_1_vl_rfs.v" \

vlog -work axi_infrastructure_v1_1_0 -64 -incr -mfcu  "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/3cbc" "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/ec67/hdl" \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/ec67/hdl/axi_infrastructure_v1_1_vl_rfs.v" \

vlog -work axi_register_slice_v2_1_33 -64 -incr -mfcu  "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/3cbc" "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/ec67/hdl" \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/3ee4/hdl/axi_register_slice_v2_1_vl_rfs.v" \

vlog -work fifo_generator_v13_2_11 -64 -incr -mfcu  "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/3cbc" "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/ec67/hdl" \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/6080/simulation/fifo_generator_vlog_beh.v" \

vcom -work fifo_generator_v13_2_11 -64 -93  \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/6080/hdl/fifo_generator_v13_2_rfs.vhd" \

vlog -work fifo_generator_v13_2_11 -64 -incr -mfcu  "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/3cbc" "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/ec67/hdl" \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/6080/hdl/fifo_generator_v13_2_rfs.v" \

vlog -work axi_data_fifo_v2_1_32 -64 -incr -mfcu  "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/3cbc" "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/ec67/hdl" \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/65ce/hdl/axi_data_fifo_v2_1_vl_rfs.v" \

vlog -work axi_crossbar_v2_1_34 -64 -incr -mfcu  "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/3cbc" "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/ec67/hdl" \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/a7e3/hdl/axi_crossbar_v2_1_vl_rfs.v" \

vlog -work xil_defaultlib -64 -incr -mfcu  "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/3cbc" "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/ec67/hdl" \
"../../../bd/soc_pwm/ip/soc_pwm_microblaze_riscv_0_axi_periph_imp_xbar_0/sim/soc_pwm_microblaze_riscv_0_axi_periph_imp_xbar_0.v" \

vcom -work axi_lite_ipif_v3_0_4 -64 -93  \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/66ea/hdl/axi_lite_ipif_v3_0_vh_rfs.vhd" \

vcom -work axi_intc_v4_1_20 -64 -93  \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/99b7/hdl/axi_intc_v4_1_vh_rfs.vhd" \

vcom -work xil_defaultlib -64 -93  \
"../../../bd/soc_pwm/ip/soc_pwm_microblaze_riscv_0_axi_intc_0/sim/soc_pwm_microblaze_riscv_0_axi_intc_0.vhd" \

vlog -work xlconcat_v2_1_6 -64 -incr -mfcu  "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/3cbc" "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/ec67/hdl" \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/6120/hdl/xlconcat_v2_1_vl_rfs.v" \

vlog -work xil_defaultlib -64 -incr -mfcu  "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/3cbc" "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/ec67/hdl" \
"../../../bd/soc_pwm/ip/soc_pwm_microblaze_riscv_0_xlconcat_0/sim/soc_pwm_microblaze_riscv_0_xlconcat_0.v" \

vcom -work mdm_riscv_v1_0_3 -64 -93  \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/d547/hdl/mdm_riscv_v1_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -64 -93  \
"../../../bd/soc_pwm/ip/soc_pwm_mdm_1_0/sim/soc_pwm_mdm_1_0.vhd" \

vcom -work lib_pkg_v1_0_4 -64 -93  \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/8c68/hdl/lib_pkg_v1_0_rfs.vhd" \

vcom -work lib_srl_fifo_v1_0_4 -64 -93  \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/1e5a/hdl/lib_srl_fifo_v1_0_rfs.vhd" \

vcom -work axi_uartlite_v2_0_37 -64 -93  \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/9a87/hdl/axi_uartlite_v2_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -64 -93  \
"../../../bd/soc_pwm/ip/soc_pwm_axi_uartlite_0_0/sim/soc_pwm_axi_uartlite_0_0.vhd" \

vlog -work xil_defaultlib -64 -incr -mfcu  "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/3cbc" "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/ec67/hdl" \
"../../../bd/soc_pwm/ipshared/bde8/hdl/myip_pwm_slave_lite_v1_0_S00_AXI.v" \
"../../../bd/soc_pwm/ipshared/bde8/src/countre.v" \
"../../../bd/soc_pwm/ipshared/bde8/src/test.v" \
"../../../bd/soc_pwm/ipshared/bde8/hdl/myip_pwm.v" \
"../../../bd/soc_pwm/ip/soc_pwm_myip_pwm_0_0/sim/soc_pwm_myip_pwm_0_0.v" \
"../../../bd/soc_pwm/ip/soc_pwm_myip_pwm_1_0/sim/soc_pwm_myip_pwm_1_0.v" \
"../../../bd/soc_pwm/ip/soc_pwm_myip_pwm_1_1/sim/soc_pwm_myip_pwm_1_1.v" \
"../../../bd/soc_pwm/ip/soc_pwm_myip_pwm_1_2/sim/soc_pwm_myip_pwm_1_2.v" \
"../../../bd/soc_pwm/ip/soc_pwm_myip_pwm_1_3/sim/soc_pwm_myip_pwm_1_3.v" \
"../../../bd/soc_pwm/ip/soc_pwm_myip_pwm_1_4/sim/soc_pwm_myip_pwm_1_4.v" \
"../../../bd/soc_pwm/ip/soc_pwm_myip_pwm_1_5/sim/soc_pwm_myip_pwm_1_5.v" \
"../../../bd/soc_pwm/ip/soc_pwm_myip_pwm_1_6/sim/soc_pwm_myip_pwm_1_6.v" \
"../../../bd/soc_pwm/sim/soc_pwm.v" \

vlog -work xil_defaultlib \
"glbl.v"

