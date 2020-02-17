import asyncio

from websocket import Socket, Message


async def start():
    async with Socket().connect("ws://127.0.0.1:4000/socket/websocket") as connection:

        async def on_state_update(state):
            print(state)
            await connection.send(Message("new", "action", {}))

        game_state_channel = await connection.channel("game_state")

        game_state_channel.on("new_state", on_state_update)
        await connection.listen()

asyncio.get_event_loop().run_until_complete(start())
