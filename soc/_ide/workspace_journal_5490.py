# 2025-09-24T15:11:12.229167
import vitis

client = vitis.create_client()
client.set_workspace(path="soc")

vitis.dispose()

