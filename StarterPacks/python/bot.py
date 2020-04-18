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
        self.tank: Tank = None

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
            Upgrade.HP_REGEN
        ])

    def destination(self, debris: Debris):
        destinationx = debris.position[0]
        destinationy = debris.position[1] + 160
        return destinationx, destinationy

    def distance_from(self, debris: Debris):
        return math.sqrt((self.tank.position[0] - debris.position[0]) ** 2 + (self.tank.position[1] - debris.position[1]) ** 2)

    def find_nearest_debris(self, state: GameState):
        return sorted(state.debris, key=lambda debris: self.distance_from(debris))[0]

    def tick(self, state: GameState) -> Action:
        self.tank = state.tanks[f"{self.id}"]
        nearest_debris: Debris = self.find_nearest_debris(state)
        return Action(
            destination=self.destination(nearest_debris),
            target=nearest_debris.position,
            purchase=self.random_upgrade()
        )
