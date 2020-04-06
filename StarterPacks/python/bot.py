import random
import math

from action import Action
from typing import Tuple


class MyBot:
    """
    Random bot
    """

    def __init__(self):
        self.id = random.randrange(0, 400)

    def random_position(self, state) -> Tuple[float]:
        x = random.randrange(0, state["map_width"])
        y = random.randrange(0, state["map_height"])
        return x, y

    def random_upgrade(self) -> str:
        return random.choice([
            Action.SPEED_UPGRADE, 
            Action.FIRE_RATE_UPGRADE, 
            Action.PROJECTILE_DAMAGE, 
            Action.MAX_HP_UPGRADE, 
            Action.BODY_DAMAGE_UPGRADE
        ])

    def destination(self, state):
        destinationx = state['debris'][self.id]['position'][0]
        destinationy = state['debris'][self.id]['position'][1] + 160
        return (destinationx, destinationy)


    def tick(self, state) -> Action:
        return Action(
            destination=self.destination(state),
            target=state['debris'][self.id]['position'],
            purchase=self.random_upgrade()
        )
