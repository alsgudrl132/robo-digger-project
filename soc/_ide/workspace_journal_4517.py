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

vitis.dispose()

