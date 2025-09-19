# 2025-09-18T20:18:36.672395
import vitis

client = vitis.create_client()
client.set_workspace(path="soc")

platform = client.get_component(name="platform_digger")
status = platform.build()

comp = client.get_component(name="app_digger")
comp.build()

client.delete_component(name="platform_digger")

client.delete_component(name="app_digger")

platform = client.create_platform_component(name = "platform_digger",hw_design = "$COMPONENT_LOCATION/../../robo-digger-project-work/soc_digger_wrapper.xsa",os = "standalone",cpu = "microblaze_riscv_0",domain_name = "standalone_microblaze_riscv_0")

comp = client.create_app_component(name="app_digger",platform = "$COMPONENT_LOCATION/../platform_digger/export/platform_digger/platform_digger.xpfm",domain = "standalone_microblaze_riscv_0",template = "hello_world")

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

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

vitis.dispose()

