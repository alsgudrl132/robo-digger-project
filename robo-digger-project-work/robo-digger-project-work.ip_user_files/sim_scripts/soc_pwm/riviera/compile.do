transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vlib riviera/lib_cdc_v1_0_3
vlib riviera/proc_sys_reset_v5_0_16
vlib riviera/xil_defaultlib
vlib riviera/microblaze_v11_0_14
vlib riviera/microblaze_riscv_v1_0_3
vlib riviera/lmb_v10_v3_0_14
vlib riviera/lmb_bram_if_cntlr_v4_0_25
vlib riviera/blk_mem_gen_v8_4_9
vlib riviera/generic_baseblocks_v2_1_2
vlib riviera/axi_infrastructure_v1_1_0
vlib riviera/axi_register_slice_v2_1_33
vlib riviera/fifo_generator_v13_2_11
vlib riviera/axi_data_fifo_v2_1_32
vlib riviera/axi_crossbar_v2_1_34
vlib riviera/axi_lite_ipif_v3_0_4
vlib riviera/axi_intc_v4_1_20
vlib riviera/xlconcat_v2_1_6
vlib riviera/mdm_riscv_v1_0_3
vlib riviera/lib_pkg_v1_0_4
vlib riviera/lib_srl_fifo_v1_0_4
vlib riviera/axi_uartlite_v2_0_37

vmap lib_cdc_v1_0_3 riviera/lib_cdc_v1_0_3
vmap proc_sys_reset_v5_0_16 riviera/proc_sys_reset_v5_0_16
vmap xil_defaultlib riviera/xil_defaultlib
vmap microblaze_v11_0_14 riviera/microblaze_v11_0_14
vmap microblaze_riscv_v1_0_3 riviera/microblaze_riscv_v1_0_3
vmap lmb_v10_v3_0_14 riviera/lmb_v10_v3_0_14
vmap lmb_bram_if_cntlr_v4_0_25 riviera/lmb_bram_if_cntlr_v4_0_25
vmap blk_mem_gen_v8_4_9 riviera/blk_mem_gen_v8_4_9
vmap generic_baseblocks_v2_1_2 riviera/generic_baseblocks_v2_1_2
vmap axi_infrastructure_v1_1_0 riviera/axi_infrastructure_v1_1_0
vmap axi_register_slice_v2_1_33 riviera/axi_register_slice_v2_1_33
vmap fifo_generator_v13_2_11 riviera/fifo_generator_v13_2_11
vmap axi_data_fifo_v2_1_32 riviera/axi_data_fifo_v2_1_32
vmap axi_crossbar_v2_1_34 riviera/axi_crossbar_v2_1_34
vmap axi_lite_ipif_v3_0_4 riviera/axi_lite_ipif_v3_0_4
vmap axi_intc_v4_1_20 riviera/axi_intc_v4_1_20
vmap xlconcat_v2_1_6 riviera/xlconcat_v2_1_6
vmap mdm_riscv_v1_0_3 riviera/mdm_riscv_v1_0_3
vmap lib_pkg_v1_0_4 riviera/lib_pkg_v1_0_4
vmap lib_srl_fifo_v1_0_4 riviera/lib_srl_fifo_v1_0_4
vmap axi_uartlite_v2_0_37 riviera/axi_uartlite_v2_0_37

vcom -work lib_cdc_v1_0_3 -93  -incr \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/2a4f/hdl/lib_cdc_v1_0_rfs.vhd" \

vcom -work proc_sys_reset_v5_0_16 -93  -incr \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/0831/hdl/proc_sys_reset_v5_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93  -incr \
"../../../bd/soc_pwm/ip/soc_pwm_proc_sys_reset_0_0/sim/soc_pwm_proc_sys_reset_0_0.vhd" \

vlog -work xil_defaultlib  -incr -v2k5 "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/3cbc" "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/ec67/hdl" -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l xil_defaultlib -l microblaze_v11_0_14 -l microblaze_riscv_v1_0_3 -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_25 -l blk_mem_gen_v8_4_9 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_33 -l fifo_generator_v13_2_11 -l axi_data_fifo_v2_1_32 -l axi_crossbar_v2_1_34 -l axi_lite_ipif_v3_0_4 -l axi_intc_v4_1_20 -l xlconcat_v2_1_6 -l mdm_riscv_v1_0_3 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_37 \
"../../../bd/soc_pwm/ip/soc_pwm_clk_wiz_0/soc_pwm_clk_wiz_0_clk_wiz.v" \
"../../../bd/soc_pwm/ip/soc_pwm_clk_wiz_0/soc_pwm_clk_wiz_0.v" \

vcom -work microblaze_v11_0_14 -93  -incr \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/a243/hdl/microblaze_v11_0_vh_rfs.vhd" \

vcom -work microblaze_riscv_v1_0_3 -93  -incr \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/f9dd/hdl/microblaze_riscv_v1_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93  -incr \
"../../../bd/soc_pwm/ip/soc_pwm_microblaze_riscv_0_0/sim/soc_pwm_microblaze_riscv_0_0.vhd" \

vcom -work lmb_v10_v3_0_14 -93  -incr \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/7495/hdl/lmb_v10_v3_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93  -incr \
"../../../bd/soc_pwm/ip/soc_pwm_dlmb_v10_0/sim/soc_pwm_dlmb_v10_0.vhd" \
"../../../bd/soc_pwm/ip/soc_pwm_ilmb_v10_0/sim/soc_pwm_ilmb_v10_0.vhd" \

vcom -work lmb_bram_if_cntlr_v4_0_25 -93  -incr \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/73e9/hdl/lmb_bram_if_cntlr_v4_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93  -incr \
"../../../bd/soc_pwm/ip/soc_pwm_dlmb_bram_if_cntlr_0/sim/soc_pwm_dlmb_bram_if_cntlr_0.vhd" \
"../../../bd/soc_pwm/ip/soc_pwm_ilmb_bram_if_cntlr_0/sim/soc_pwm_ilmb_bram_if_cntlr_0.vhd" \

vlog -work blk_mem_gen_v8_4_9  -incr -v2k5 "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/3cbc" "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/ec67/hdl" -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l xil_defaultlib -l microblaze_v11_0_14 -l microblaze_riscv_v1_0_3 -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_25 -l blk_mem_gen_v8_4_9 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_33 -l fifo_generator_v13_2_11 -l axi_data_fifo_v2_1_32 -l axi_crossbar_v2_1_34 -l axi_lite_ipif_v3_0_4 -l axi_intc_v4_1_20 -l xlconcat_v2_1_6 -l mdm_riscv_v1_0_3 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_37 \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/5ec1/simulation/blk_mem_gen_v8_4.v" \

vlog -work xil_defaultlib  -incr -v2k5 "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/3cbc" "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/ec67/hdl" -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l xil_defaultlib -l microblaze_v11_0_14 -l microblaze_riscv_v1_0_3 -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_25 -l blk_mem_gen_v8_4_9 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_33 -l fifo_generator_v13_2_11 -l axi_data_fifo_v2_1_32 -l axi_crossbar_v2_1_34 -l axi_lite_ipif_v3_0_4 -l axi_intc_v4_1_20 -l xlconcat_v2_1_6 -l mdm_riscv_v1_0_3 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_37 \
"../../../bd/soc_pwm/ip/soc_pwm_lmb_bram_0/sim/soc_pwm_lmb_bram_0.v" \

vlog -work generic_baseblocks_v2_1_2  -incr -v2k5 "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/3cbc" "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/ec67/hdl" -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l xil_defaultlib -l microblaze_v11_0_14 -l microblaze_riscv_v1_0_3 -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_25 -l blk_mem_gen_v8_4_9 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_33 -l fifo_generator_v13_2_11 -l axi_data_fifo_v2_1_32 -l axi_crossbar_v2_1_34 -l axi_lite_ipif_v3_0_4 -l axi_intc_v4_1_20 -l xlconcat_v2_1_6 -l mdm_riscv_v1_0_3 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_37 \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/0c28/hdl/generic_baseblocks_v2_1_vl_rfs.v" \

vlog -work axi_infrastructure_v1_1_0  -incr -v2k5 "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/3cbc" "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/ec67/hdl" -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l xil_defaultlib -l microblaze_v11_0_14 -l microblaze_riscv_v1_0_3 -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_25 -l blk_mem_gen_v8_4_9 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_33 -l fifo_generator_v13_2_11 -l axi_data_fifo_v2_1_32 -l axi_crossbar_v2_1_34 -l axi_lite_ipif_v3_0_4 -l axi_intc_v4_1_20 -l xlconcat_v2_1_6 -l mdm_riscv_v1_0_3 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_37 \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/ec67/hdl/axi_infrastructure_v1_1_vl_rfs.v" \

vlog -work axi_register_slice_v2_1_33  -incr -v2k5 "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/3cbc" "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/ec67/hdl" -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l xil_defaultlib -l microblaze_v11_0_14 -l microblaze_riscv_v1_0_3 -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_25 -l blk_mem_gen_v8_4_9 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_33 -l fifo_generator_v13_2_11 -l axi_data_fifo_v2_1_32 -l axi_crossbar_v2_1_34 -l axi_lite_ipif_v3_0_4 -l axi_intc_v4_1_20 -l xlconcat_v2_1_6 -l mdm_riscv_v1_0_3 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_37 \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/3ee4/hdl/axi_register_slice_v2_1_vl_rfs.v" \

vlog -work fifo_generator_v13_2_11  -incr -v2k5 "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/3cbc" "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/ec67/hdl" -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l xil_defaultlib -l microblaze_v11_0_14 -l microblaze_riscv_v1_0_3 -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_25 -l blk_mem_gen_v8_4_9 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_33 -l fifo_generator_v13_2_11 -l axi_data_fifo_v2_1_32 -l axi_crossbar_v2_1_34 -l axi_lite_ipif_v3_0_4 -l axi_intc_v4_1_20 -l xlconcat_v2_1_6 -l mdm_riscv_v1_0_3 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_37 \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/6080/simulation/fifo_generator_vlog_beh.v" \

vcom -work fifo_generator_v13_2_11 -93  -incr \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/6080/hdl/fifo_generator_v13_2_rfs.vhd" \

vlog -work fifo_generator_v13_2_11  -incr -v2k5 "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/3cbc" "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/ec67/hdl" -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l xil_defaultlib -l microblaze_v11_0_14 -l microblaze_riscv_v1_0_3 -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_25 -l blk_mem_gen_v8_4_9 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_33 -l fifo_generator_v13_2_11 -l axi_data_fifo_v2_1_32 -l axi_crossbar_v2_1_34 -l axi_lite_ipif_v3_0_4 -l axi_intc_v4_1_20 -l xlconcat_v2_1_6 -l mdm_riscv_v1_0_3 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_37 \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/6080/hdl/fifo_generator_v13_2_rfs.v" \

vlog -work axi_data_fifo_v2_1_32  -incr -v2k5 "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/3cbc" "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/ec67/hdl" -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l xil_defaultlib -l microblaze_v11_0_14 -l microblaze_riscv_v1_0_3 -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_25 -l blk_mem_gen_v8_4_9 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_33 -l fifo_generator_v13_2_11 -l axi_data_fifo_v2_1_32 -l axi_crossbar_v2_1_34 -l axi_lite_ipif_v3_0_4 -l axi_intc_v4_1_20 -l xlconcat_v2_1_6 -l mdm_riscv_v1_0_3 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_37 \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/65ce/hdl/axi_data_fifo_v2_1_vl_rfs.v" \

vlog -work axi_crossbar_v2_1_34  -incr -v2k5 "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/3cbc" "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/ec67/hdl" -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l xil_defaultlib -l microblaze_v11_0_14 -l microblaze_riscv_v1_0_3 -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_25 -l blk_mem_gen_v8_4_9 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_33 -l fifo_generator_v13_2_11 -l axi_data_fifo_v2_1_32 -l axi_crossbar_v2_1_34 -l axi_lite_ipif_v3_0_4 -l axi_intc_v4_1_20 -l xlconcat_v2_1_6 -l mdm_riscv_v1_0_3 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_37 \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/a7e3/hdl/axi_crossbar_v2_1_vl_rfs.v" \

vlog -work xil_defaultlib  -incr -v2k5 "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/3cbc" "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/ec67/hdl" -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l xil_defaultlib -l microblaze_v11_0_14 -l microblaze_riscv_v1_0_3 -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_25 -l blk_mem_gen_v8_4_9 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_33 -l fifo_generator_v13_2_11 -l axi_data_fifo_v2_1_32 -l axi_crossbar_v2_1_34 -l axi_lite_ipif_v3_0_4 -l axi_intc_v4_1_20 -l xlconcat_v2_1_6 -l mdm_riscv_v1_0_3 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_37 \
"../../../bd/soc_pwm/ip/soc_pwm_microblaze_riscv_0_axi_periph_imp_xbar_0/sim/soc_pwm_microblaze_riscv_0_axi_periph_imp_xbar_0.v" \

vcom -work axi_lite_ipif_v3_0_4 -93  -incr \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/66ea/hdl/axi_lite_ipif_v3_0_vh_rfs.vhd" \

vcom -work axi_intc_v4_1_20 -93  -incr \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/99b7/hdl/axi_intc_v4_1_vh_rfs.vhd" \

vcom -work xil_defaultlib -93  -incr \
"../../../bd/soc_pwm/ip/soc_pwm_microblaze_riscv_0_axi_intc_0/sim/soc_pwm_microblaze_riscv_0_axi_intc_0.vhd" \

vlog -work xlconcat_v2_1_6  -incr -v2k5 "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/3cbc" "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/ec67/hdl" -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l xil_defaultlib -l microblaze_v11_0_14 -l microblaze_riscv_v1_0_3 -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_25 -l blk_mem_gen_v8_4_9 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_33 -l fifo_generator_v13_2_11 -l axi_data_fifo_v2_1_32 -l axi_crossbar_v2_1_34 -l axi_lite_ipif_v3_0_4 -l axi_intc_v4_1_20 -l xlconcat_v2_1_6 -l mdm_riscv_v1_0_3 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_37 \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/6120/hdl/xlconcat_v2_1_vl_rfs.v" \

vlog -work xil_defaultlib  -incr -v2k5 "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/3cbc" "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/ec67/hdl" -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l xil_defaultlib -l microblaze_v11_0_14 -l microblaze_riscv_v1_0_3 -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_25 -l blk_mem_gen_v8_4_9 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_33 -l fifo_generator_v13_2_11 -l axi_data_fifo_v2_1_32 -l axi_crossbar_v2_1_34 -l axi_lite_ipif_v3_0_4 -l axi_intc_v4_1_20 -l xlconcat_v2_1_6 -l mdm_riscv_v1_0_3 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_37 \
"../../../bd/soc_pwm/ip/soc_pwm_microblaze_riscv_0_xlconcat_0/sim/soc_pwm_microblaze_riscv_0_xlconcat_0.v" \

vcom -work mdm_riscv_v1_0_3 -93  -incr \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/d547/hdl/mdm_riscv_v1_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93  -incr \
"../../../bd/soc_pwm/ip/soc_pwm_mdm_1_0/sim/soc_pwm_mdm_1_0.vhd" \

vcom -work lib_pkg_v1_0_4 -93  -incr \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/8c68/hdl/lib_pkg_v1_0_rfs.vhd" \

vcom -work lib_srl_fifo_v1_0_4 -93  -incr \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/1e5a/hdl/lib_srl_fifo_v1_0_rfs.vhd" \

vcom -work axi_uartlite_v2_0_37 -93  -incr \
"../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/9a87/hdl/axi_uartlite_v2_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93  -incr \
"../../../bd/soc_pwm/ip/soc_pwm_axi_uartlite_0_0/sim/soc_pwm_axi_uartlite_0_0.vhd" \

vlog -work xil_defaultlib  -incr -v2k5 "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/3cbc" "+incdir+../../../../robo-digger-project-work.gen/sources_1/bd/soc_pwm/ipshared/ec67/hdl" -l lib_cdc_v1_0_3 -l proc_sys_reset_v5_0_16 -l xil_defaultlib -l microblaze_v11_0_14 -l microblaze_riscv_v1_0_3 -l lmb_v10_v3_0_14 -l lmb_bram_if_cntlr_v4_0_25 -l blk_mem_gen_v8_4_9 -l generic_baseblocks_v2_1_2 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_33 -l fifo_generator_v13_2_11 -l axi_data_fifo_v2_1_32 -l axi_crossbar_v2_1_34 -l axi_lite_ipif_v3_0_4 -l axi_intc_v4_1_20 -l xlconcat_v2_1_6 -l mdm_riscv_v1_0_3 -l lib_pkg_v1_0_4 -l lib_srl_fifo_v1_0_4 -l axi_uartlite_v2_0_37 \
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

