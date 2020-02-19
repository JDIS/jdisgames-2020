import asyncio
import dataclasses
import random

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


async def start():
    async with Socket().connect("ws://127.0.0.1:4000/socket/websocket") as connection:

        async def on_state_update(state):
            payload = dataclasses.asdict(bot.tick(state))
            payload.update({"tank_id": 1})
            await connection.send(Message("new", "action", payload))

        action_channel: Channel = await connection.channel("action")
        game_state_channel = await connection.channel("game_state")


        game_state_channel.on("new_state", on_state_update)

        await connection.listen()

asyncio.get_event_loop().run_until_complete(start())
