transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

asim +access +r +m+xadc_wiz_1  -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.xadc_wiz_1 xil_defaultlib.glbl

do {xadc_wiz_1.udo}

run 1000ns

endsim

quit -force
