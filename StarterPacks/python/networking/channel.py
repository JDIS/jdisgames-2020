from networking.message import JoinMessage, Message


class Channel:
    def __init__(self, topic, socket):

        async def on_reply(message):
            pass

        self._callbacks = {}
        self._socket = socket
        self.on(Message.PHX_REPLY, on_reply)

    @classmethod
    async def create(self, topic, socket, payload) -> 'Channel':
        channel = Channel(topic, socket)
        await socket.send(JoinMessage(topic, payload))
        return channel

    def on(self, event, callback):
        self._callbacks[event] = callback

    async def handle(self, message):
        if self._callbacks.get(message.event):
            return await self._callbacks[message.event](message.payload)
