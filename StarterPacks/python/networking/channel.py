
import asyncio
import itertools
import logging

from networking.push import Push
from networking.message import JoinMessage


class Channel:
    def __init__(self, topic: str, socket):
        self._topic = topic
        self._socket = socket
        self._callbacks = {}
        self._ref_counter = itertools.count()
        self._pushes = {}

    async def __aenter__(self):
        await self.join()
        return self

    async def __aexit__(self, _, __, ___):
        pass

    async def join(self):
        join_message = JoinMessage(self._topic, self._create_ref())
        response_event = asyncio.Event()

        def handle_join_success(_):
            logging.info(f"Connected to channel {self._topic}")
            response_event.set()

        def handle_join_error(response):
            logging.error(
                f"Couldn't connect to channel \"{self._topic}\": {response.payload['response']['error']}")
            quit()

        self._socket._register_channel(self._topic, self._handle_message)

        join_push = await self.push(join_message.event, join_message.payload)
        join_push.receive(
            "ok", handle_join_success
        ).receive("error", handle_join_error)

        return await response_event.wait()

    def on(self, event, callback):
        self._callbacks[event] = callback

    async def push(self, event, payload):
        push = Push(event, self, payload, self._create_ref())
        self._register_push(push)
        await push._send()
        return push

    def _register_push(self, push):
        self._pushes[push._ref] = push

    def _handle_message(self, message):
        if message.event == "phx_reply":
            if self._pushes.get(message.ref):
                self._pushes[message.ref]._handle_reply(message)

            return

        if self._callbacks.get(message.event):
            self._callbacks[message.event](message.payload)

    def _create_ref(self):
        return next(self._ref_counter)
