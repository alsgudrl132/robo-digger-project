# 2025-09-16T18:36:24.684812
import vitis

client = vitis.create_client()
client.set_workspace(path="soc")

platform = client.get_component(name="platform_pwm")
status = platform.build()

comp = client.get_component(name="app_pwm")
comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

client.delete_component(name="app_joystick")

platform = client.create_platform_component(name = "platform_jy",hw_design = "$COMPONENT_LOCATION/../../robo-digger-project-work/soc_pwm_led_wrapper_adc_uart_btn_lcd.xsa",os = "standalone",cpu = "microblaze_riscv_0",domain_name = "standalone_microblaze_riscv_0")

comp = client.create_app_component(name="app_jy",platform = "$COMPONENT_LOCATION/../platform_jy/export/platform_jy/platform_jy.xpfm",domain = "standalone_microblaze_riscv_0",template = "hello_world")

platform = client.get_component(name="platform_jy")
status = platform.build()

comp = client.get_component(name="app_jy")
comp.build()

