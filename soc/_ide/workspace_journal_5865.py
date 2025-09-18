# 2025-09-17T09:01:50.987392
import vitis

client = vitis.create_client()
client.set_workspace(path="soc")

platform = client.get_component(name="platform_jy")
status = platform.build()

comp = client.get_component(name="app_jy")
comp.build()

