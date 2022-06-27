
import logging

from networking.message import Message


logging.basicConfig(level=logging.INFO)


class Push:
    def __init__(self, event, channel, payload, ref):
        self._event = event
        self._channel = channel
        self._payload = payload
        self._ref = ref
        self._status_callbacks = {}

    async def _send(self):
        message = Message(self._event, self._channel._topic,
                          self._payload, self._ref)
        await self._channel._socket._websocket.send(message.to_json())

    def receive(self, status, callback):
        self._status_callbacks[status] = callback
        return self

    def _handle_reply(self, message: Message):
        status = message.payload["status"]
        response = message.payload["response"]
        handler = self._status_callbacks.get(status)
        if handler is not None:
            handler(response)
