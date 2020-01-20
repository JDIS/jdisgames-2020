import asyncio

from websocket import Socket, Message

async def start():
    async with Socket().connect("ws://127.0.0.1:4000/socket/websocket") as connection:

        async def on_message(message):
            print(message)
            await connection.send(Message("something", "room:lobby", {}))

        channel = await connection.channel("room:lobby")
        channel.on("new_msg", on_message)
        await connection.listen()

asyncio.get_event_loop().run_until_complete(start())