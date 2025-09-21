# 2025-09-21T10:19:06.296197
import vitis

client = vitis.create_client()
client.set_workspace(path="soc")

platform = client.get_component(name="platform_lcd_jy")
status = platform.build()

comp = client.get_component(name="app_lcd_jy")
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

