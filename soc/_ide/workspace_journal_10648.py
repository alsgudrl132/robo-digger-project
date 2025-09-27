# 2025-09-26T11:29:20.265509
import vitis

client = vitis.create_client()
client.set_workspace(path="soc")

platform = client.get_component(name="platform_lcd_jy")
status = platform.build()

comp = client.get_component(name="app_lcd_jy")
comp.build()

vitis.dispose()

