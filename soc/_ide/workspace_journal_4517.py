# 2025-09-16T17:47:35.210760
import vitis

client = vitis.create_client()
client.set_workspace(path="soc")

platform = client.create_platform_component(name = "platform_pwm",hw_design = "$COMPONENT_LOCATION/../../robo-digger-project-work/soc_pwm_wrapper.xsa",os = "standalone",cpu = "microblaze_riscv_0",domain_name = "standalone_microblaze_riscv_0")

comp = client.create_app_component(name="app_pwm",platform = "$COMPONENT_LOCATION/../platform_pwm/export/platform_pwm/platform_pwm.xpfm",domain = "standalone_microblaze_riscv_0",template = "hello_world")

platform = client.get_component(name="platform_pwm")
status = platform.build()

comp = client.get_component(name="app_pwm")
comp.build()

status = platform.build()

comp.build()

vitis.dispose()

