# 2025-09-19T10:19:53.738889
import vitis

client = vitis.create_client()
client.set_workspace(path="soc")

platform = client.get_component(name="platform_digger")
status = platform.build()

comp = client.get_component(name="app_digger")
comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

platform = client.get_component(name="platform_pwm")
status = platform.build()

comp = client.get_component(name="app_pwm")
comp.build()

platform = client.get_component(name="platform_digger")
status = platform.build()

comp = client.get_component(name="app_digger")
comp.build()

