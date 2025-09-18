# 2025-09-17T16:22:09.371455
import vitis

client = vitis.create_client()
client.set_workspace(path="soc")

platform = client.get_component(name="platform_digger")
status = platform.build()

comp = client.get_component(name="app_digger")
comp.build()

status = platform.build()

comp.build()

platform = client.get_component(name="platform_uart")
status = platform.build()

comp = client.get_component(name="app_uart")
comp.build()

platform = client.get_component(name="platform_digger")
status = platform.build()

comp = client.get_component(name="app_digger")
comp.build()

platform = client.get_component(name="platform_uart")
status = platform.build()

comp = client.get_component(name="app_uart")
comp.build()

platform = client.get_component(name="platform_digger")
status = platform.build()

comp = client.get_component(name="app_digger")
comp.build()

