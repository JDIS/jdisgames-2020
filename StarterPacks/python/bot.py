import random
from typing import Tuple

from Action import Action
from GameState import GameState
from Upgrades import Upgrade


class MyBot:
    """
    Random bot
    """

    def __init__(self):
        self.id = random.randrange(0, 400)

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
            Upgrade.BODY_DAMAGE_UPGRADE
        ])

    def destination(self, state: GameState):
        destinationx = state.debris[self.id].position[0]
        destinationy = state.debris[self.id].position[1] + 160
        return destinationx, destinationy

    def tick(self, state: GameState) -> Action:
        return Action(
            destination=self.destination(state),
            target=state.debris[self.id].position,
            purchase=self.random_upgrade()
        )
