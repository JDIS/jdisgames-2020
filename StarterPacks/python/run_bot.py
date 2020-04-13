import argparse
import asyncio
import dataclasses

import dacite as dacite
from dacite import Config

from bot import MyBot
from channel import Channel
from GameState import GameState
from websocket import Message, Socket

BASE_URL = "ws://127.0.0.1:4000/socket"


async def start(bot, secret_key):
    bot_url = f"{BASE_URL}/bot/websocket?secret={secret_key}"
    spectate_url = f"{BASE_URL}/spectate/websocket"

    async with Socket().connect(bot_url) as bot_connection:
        async with Socket().connect(spectate_url) as spectate_connection:

            async def on_state_update(state):
                parsed_state = dacite.from_dict(GameState, state, Config(check_types=False))
                payload = dataclasses.asdict(bot.tick(parsed_state))
                await bot_connection.send(Message("new", "action", payload))

            action_channel: Channel = await bot_connection.channel("action")
            game_state_channel = await spectate_connection.channel("game_state")

            game_state_channel.on("new_state", on_state_update)

            await spectate_connection.listen()


def loop(secret):
    asyncio.get_event_loop().run_until_complete(start(MyBot(), secret))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Starts your bot!")
    parser.add_argument("secret", help="The secret which authentifies your bot")
    args = parser.parse_args()
    asyncio.get_event_loop().run_until_complete(start(MyBot(), args.secret))
