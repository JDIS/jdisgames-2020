import asyncio
import json
import websockets
import logging

from async_generator import asynccontextmanager
from message import Message, JoinMessage
from channel import Channel

logging.basicConfig(level=logging.INFO)

class Socket:
    def __init__(self):
        self._websocket = None
        self._channels = {}

    @asynccontextmanager
    async def connect(self, endpoint):
        try:
            self._websocket = await websockets.connect(endpoint)
            yield self
        finally:
            await self._websocket.close()

    async def channel(self, topic):
        if self._channels.get(topic):
            return self._channels[topic]

        self._channels[topic] = await Channel.create(topic, self)
        return self._channels[topic]

    async def send(self, message):
        logging.info("Sending: {}".format(message.to_json()))
        await self._websocket.send(message.to_json())

    async def listen(self):
        while True:
            message = await self._websocket.recv()
            logging.info("Receiving: {}".format(message))
            message = Message.from_json(message)
            asyncio.ensure_future(self._dispatch(message))

    async def _dispatch(self, message):
        if self._channels.get(message.topic):
            await self._channels[message.topic].handle(message)
