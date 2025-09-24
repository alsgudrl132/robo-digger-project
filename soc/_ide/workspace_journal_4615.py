# 2025-09-23T18:00:40.478763
import vitis

client = vitis.create_client()
client.set_workspace(path="soc")

vitis.dispose()

