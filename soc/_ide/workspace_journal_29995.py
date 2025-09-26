# 2025-09-25T10:55:24.687430
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

platform = client.get_component(name="platform_uart")
status = platform.build()

comp = client.get_component(name="app_uart")
comp.build()

platform = client.get_component(name="platform_digger")
status = platform.build()

comp = client.get_component(name="app_digger")
comp.build()

status = platform.build()

comp.build()

platform = client.get_component(name="platform_lcd_jy")
status = platform.build()

comp = client.get_component(name="app_lcd_jy")
comp.build()

platform = client.get_component(name="platform_digger")
status = platform.build()

comp = client.get_component(name="app_digger")
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

status = platform.build()

comp.build()

vitis.dispose()

