import random

from action import Action
from typing import Tuple


class MyBot:
    """
    Random bot
    """

    def random_position(self, state) -> Tuple[float]:
        x = random.randrange(0, state["map_width"])
        y = random.randrange(0, state["map_height"])
        return x, y

    def tick(self, state) -> Action:
        return Action(
            destination=self.random_position(state), target=self.random_position(state)
        )
