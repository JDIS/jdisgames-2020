import asyncio
import logging
import ssl

import websockets

from networking.message import Message
from networking.channel import Channel

logging.basicConfig(level=logging.INFO)


class Socket:
    def __init__(self, url):
        self._url = url
        self._websocket = None
        self._channel_callbacks = {}

    async def __aenter__(self):
        await self.connect()
        self._listen()
        return self

    async def __aexit__(self, _, __, ___):
        await self.disconnect()

    async def connect(self):
        ctx = None
        if self._url.startswith('wss'):
            ctx = ssl.create_default_context()
            ctx.check_hostname = False
            ctx.verify_mode = ssl.CERT_NONE
        self._websocket = await websockets.connect(self._url, ssl=ctx)
        logging.info(f"Connected to socket at {self._url}")

    async def disconnect(self):
        await self._websocket.close()

    def channel(self, topic):
        return Channel(topic, self)

    def _register_channel(self, topic, callback):
        self._channel_callbacks[topic] = callback

    async def _receive(self):
        message = await self._websocket.recv()
        logging.debug("Receiving: {}".format(message))
        message = Message.from_json(message)
        asyncio.ensure_future(self._dispatch(message))
        return message

    def _listen(self):
        async def async_listen():
            while True:
                await self._receive()

        asyncio.ensure_future(async_listen())

    async def _dispatch(self, message):
        handler = self._channel_callbacks.get(message.topic)
        if handler is not None:
            handler(message)
