import argparse
import asyncio
import dataclasses

import dacite as dacite
from dacite import Config

from bot import MyBot
from core import GameState
from networking import Channel, Message, Socket

BASE_URL = "ws://127.0.0.1:4000/socket"


async def start(secret_key):
    bot_url = f"{BASE_URL}/bot/websocket?secret={secret_key}"
    spectate_url = f"{BASE_URL}/spectate/websocket"

    async with Socket().connect(bot_url) as bot_connection:
        async with Socket().connect(spectate_url) as spectate_connection:

            bot = None

            async def on_state_update(state):
                global bot

                parsed_state = dacite.from_dict(
                    GameState, state, Config(check_types=False))
                payload = dataclasses.asdict(bot.tick(parsed_state))
                await bot_connection.send(Message("new", "action", payload))

            async def on_receive_id(id):
                global bot

                bot = MyBot(id["id"])

            action_channel: Channel = await bot_connection.channel("action")
            game_state_channel = await spectate_connection.channel("game_state")

            action_channel.on("id", on_receive_id)
            game_state_channel.on("new_state", on_state_update)

            # Receive channel join confirmation
            await bot_connection.receive()
            # Receive id
            await bot_connection.receive()
            # Start listening for game state updates
            await spectate_connection.listen()


def loop(secret):
    asyncio.get_event_loop().run_until_complete(start(secret))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Starts your bot!")
    parser.add_argument(
        "secret", help="The secret which authentifies your bot")
    args = parser.parse_args()
    asyncio.get_event_loop().run_until_complete(start(args.secret))
