from dataclasses import dataclass
from typing import Tuple

from Upgrades import Upgrades


@dataclass()
class Tank:
    """
    Represents a tank (you or enemy) and all its stats.
    """
    id: int
    name: str
    max_hp: int
    current_hp: int
    speed: int
    position: Tuple[int, int]
    """ x, y """

    score: int
    fire_rate: float
    projectile_damage: int
    body_damage: int
    has_died: bool
    cooldown: int
    experience: int
    cannon_angle: float
    """ degrees """

    upgrade_tokens: int
    upgrade_levels: Upgrades
