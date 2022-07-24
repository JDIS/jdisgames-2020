import math
import random
from typing import Tuple

from core import Action, GameState, Upgrade, Debris, Tank


class MyBot:
    """
    Random bot
    """

    def __init__(self, id):
        self.id = id

    def random_position(self, state: GameState) -> Tuple[float]:
        x = random.randrange(0, state.map_width)
        y = random.randrange(0, state.map_height)
        return x, y

    def random_upgrade(self) -> Upgrade:
        return random.choice([
            Upgrade.SPEED_UPGRADE,
            Upgrade.FIRE_RATE_UPGRADE,
            Upgrade.PROJECTILE_DAMAGE,
            Upgrade.MAX_HP_UPGRADE,
            Upgrade.BODY_DAMAGE_UPGRADE,
            Upgrade.HP_REGEN,
            Upgrade.PROJECTILE_TIME_TO_LIVE
        ])

    def tick(self, state: GameState) -> Action:
        # Program your bot here

        return Action(
            destination=self.random_position(state),
            target=self.random_position(state),
            purchase=self.random_upgrade()
        )
