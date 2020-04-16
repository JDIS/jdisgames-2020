import argparse
import asyncio
import dataclasses
import logging
import traceback
from asyncio import Queue

import dacite as dacite
from dacite import Config

from bot import MyBot
from core import GameState
from networking import Channel, Message, Socket

BASE_URL = "ws://127.0.0.1:4000/socket"


async def start(secret_key, loop):
    bot_url = f"{BASE_URL}/bot/websocket?secret={secret_key}"
    spectate_url = f"{BASE_URL}/spectate/websocket"

    async with Socket().connect(bot_url) as bot_connection:
        async with Socket().connect(spectate_url) as spectate_connection:

            bot = None
            queue: Queue = Queue(maxsize=1)

            async def on_state_update(state):
                global bot

                parsed_state = dacite.from_dict(
                    GameState, state, Config(check_types=False))
                if queue.qsize() > 0:
                    queue.get_nowait()
                queue.put_nowait(parsed_state)

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

            # start the tick task
            task = loop.create_task(tick(queue, bot_connection))

            # Start listening for game state updates
            await spectate_connection.listen()


async def tick(queue: Queue, bot_connection):
    """
    Task that infinitely send bot actions to the server with the latest
    game_state available.
    :param queue: The game update Queue
    :param bot_connection: The socket to send bot actions to
    """
    while True:
        parsed_state = await queue.get()
        try:
            tick = bot.tick(parsed_state)
        except Exception as e:
            logging.error(f"An error was raised while doing a bot tick: {e}")
            e.with_traceback(None)
            traceback.print_exc()
            continue
        payload = dataclasses.asdict(tick)
        await bot_connection.send(Message("new", "action", payload))


def loop(secret):
    asyncio.get_event_loop().run_until_complete(start(secret, asyncio.get_event_loop()))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Starts your bot!")
    parser.add_argument(
        "secret", help="The secret which authentifies your bot")
    args = parser.parse_args()
    asyncio.get_event_loop().run_until_complete(start(args.secret, asyncio.get_event_loop()))
