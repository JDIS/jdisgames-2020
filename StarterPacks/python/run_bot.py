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
from networking import Socket

DEFAULT_BASE_URL = "ws://127.0.0.1:4000/socket"


def get_game_name(is_ranked):
    return "main_game" if is_ranked else "secondary_game"


async def start(secret_key, loop, is_ranked, backend_url):
    bot_url = f"{backend_url}/bot/websocket?secret={secret_key}"
    spectate_url = f"{backend_url}/spectate/websocket"

    game_name = get_game_name(is_ranked)

    async with Socket(bot_url) as bot_socket:
        async with Socket(spectate_url) as spectate_socket:
            async with bot_socket.channel(f"action:{game_name}") as action_channel:
                async with spectate_socket.channel(f"game_state:{game_name}") as game_state_channel:

                    queue: Queue = Queue(maxsize=1)

                    def on_state_update(state):
                        parsed_state = dacite.from_dict(
                            GameState, state, Config(check_types=False))
                        try:
                            queue.get_nowait()
                        except:
                            pass
                        queue.put_nowait(parsed_state)

                    def on_receive_id(response):
                        global bot

                        id = response["id"]

                        bot = MyBot(id)

                        game_state_channel.on("new_state", on_state_update)

                    id_push = await action_channel.push("get_id", {})
                    id_push.receive(
                        "ok", on_receive_id)

                    loop.create_task(tick(queue, action_channel))
                    await asyncio.Event().wait()


async def tick(queue: Queue, action_channel):
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
        await action_channel.push("new", payload)


def loop(secret, is_ranked, backend_url):
    asyncio.get_event_loop().run_until_complete(
        start(secret, asyncio.get_event_loop(), is_ranked, backend_url))


def str2bool(v):
    if isinstance(v, bool):
        return v
    if v.lower() in ('yes', 'true', 't', 'y', '1'):
        return True
    elif v.lower() in ('no', 'false', 'f', 'n', '0'):
        return False
    else:
        raise argparse.ArgumentTypeError('Boolean value expected.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Starts your bot!")
    parser.add_argument(
        "-s", "--secret", help="The secret which authenticates your bot", required=True)
    parser.add_argument(
        "-r", "--is_ranked", help="Whether the bot should connect to the ranked game (True) or the practice one (False). Defaults to True", type=str2bool, const=True, default=True, nargs='?')
    parser.add_argument("-u", "--backend_url", help="The url of the backend server", const=True, default=DEFAULT_BASE_URL, nargs="?")
    args = parser.parse_args()

    loop(args.secret, args.is_ranked, args.backend_url)
