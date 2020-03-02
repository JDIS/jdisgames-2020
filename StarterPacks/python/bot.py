import asyncio
import dataclasses
import random
import sys

from action import Action
from channel import Channel
from websocket import Message, Socket


class MyBot:
    """
    Random bot
    """

    def tick(self, state) -> Action:
        return Action(destination=(random.randrange(0, state['map_width']), random.randrange(0, state['map_height'])))


bot = MyBot()


async def start(secret_key):

    async with Socket().connect(f"ws://127.0.0.1:4000/socket/bot/websocket?secret={secret_key}") as bot_connection:
        async with Socket().connect("ws://127.0.0.1:4000/socket/spectate/websocket") as spectate_connection:

            async def on_state_update(state):
                payload = dataclasses.asdict(bot.tick(state))
                await bot_connection.send(Message("new", "action", payload))

            action_channel: Channel = await bot_connection.channel("action")
            game_state_channel = await spectate_connection.channel("game_state")

            game_state_channel.on("new_state", on_state_update)

            await spectate_connection.listen()

if len(sys.argv) < 2:
    print("Missing required argument: authentication secret")
    exit()

asyncio.get_event_loop().run_until_complete(start(sys.argv[1]))
