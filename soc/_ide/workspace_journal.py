# 2025-09-16T18:58:33.866087
import vitis

client = vitis.create_client()
client.set_workspace(path="soc")

platform = client.get_component(name="platform_jy")
status = platform.build()

comp = client.get_component(name="app_jy")
comp.build()

platform = client.get_component(name="platform_pwm")
status = platform.build()

comp = client.get_component(name="app_pwm")
comp.build()

platform = client.create_platform_component(name = "platform_uart",hw_design = "$COMPONENT_LOCATION/../../robo-digger-project-work/soc_uart_wrapper.xsa",os = "standalone",cpu = "microblaze_riscv_0",domain_name = "standalone_microblaze_riscv_0")

client.delete_component(name="platform_uart")

platform = client.create_platform_component(name = "platform_uart",hw_design = "$COMPONENT_LOCATION/../../robo-digger-project-work/soc_uart_wrapper.xsa",os = "standalone",cpu = "microblaze_riscv_0",domain_name = "standalone_microblaze_riscv_0")

comp = client.create_app_component(name="app_uart",platform = "$COMPONENT_LOCATION/../platform_uart/export/platform_uart/platform_uart.xpfm",domain = "standalone_microblaze_riscv_0",template = "hello_world")

platform = client.get_component(name="platform_uart")
status = platform.build()

comp = client.get_component(name="app_uart")
comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

client.delete_component(name="platform_uart")

client.delete_component(name="app_uart")

platform = client.create_platform_component(name = "app_uart",hw_design = "$COMPONENT_LOCATION/../../robo-digger-project-work/soc_uart_wrapper.xsa",os = "standalone",cpu = "microblaze_riscv_0",domain_name = "standalone_microblaze_riscv_0")

client.delete_component(name="app_uart")

platform = client.create_platform_component(name = "platform_uart",hw_design = "$COMPONENT_LOCATION/../../robo-digger-project-work/soc_uart_wrapper.xsa",os = "standalone",cpu = "microblaze_riscv_0",domain_name = "standalone_microblaze_riscv_0")

comp = client.create_app_component(name="app_uart",platform = "$COMPONENT_LOCATION/../platform_uart/export/platform_uart/platform_uart.xpfm",domain = "standalone_microblaze_riscv_0",template = "hello_world")

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

