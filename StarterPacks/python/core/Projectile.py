from dataclasses import dataclass
from typing import Tuple


@dataclass()
class Projectile:
    """ Represents an active projectile on the map """
    id: int
    owner_id: int
    radius: int
    speed: int
    damage: int
    angle: float
    time_to_live: int
    """ number of iterations before the projectile disappears """

    position: Tuple[int, int]
    """ x, y """
