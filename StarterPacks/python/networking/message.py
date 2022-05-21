import json


class Message:

    PHX_JOIN = "phx_join"
    PHX_EVENT = "phx_event"
    PHX_REPLY = "phx_reply"

    def __init__(self, event, topic, payload):
        self.event = event
        self.topic = topic
        self.payload = payload
        self.ref = None

    def to_json(self):
        return json.dumps({
            "topic": self.topic,
            "event": self.event,
            "payload": self.payload,
            "ref": None
        }, default=str)

    @staticmethod
    def from_json(message):
        message = json.loads(message)
        return Message(
            message["event"],
            message["topic"],
            message["payload"]
        )


class JoinMessage(Message):
    def __init__(self, topic):
        self.event = Message.PHX_JOIN
        self.topic = topic
        self.payload = {}
        self.ref = None
