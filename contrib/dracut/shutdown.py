import asyncio
from qemu.qmp import QMPClient


async def main():
    qmp = QMPClient("dracut-vm")
    await qmp.connect("/tmp/qmp.sock")

    await qmp.execute("system_powerdown")

    await qmp.disconnect()


asyncio.run(main())
