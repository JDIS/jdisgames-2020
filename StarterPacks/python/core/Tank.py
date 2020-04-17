from dataclasses import dataclass
from typing import Tuple

from core.Upgrades import Upgrades


@dataclass()
class Tank:
    """
    Represents a tank (you or enemy) and all its stats.
    """
    id: str
    name: str
    max_hp: int
    current_hp: float
    speed: int
    position: Tuple[int, int]
    """ x, y """

    score: int
    fire_rate: float
    projectile_damage: int
    body_damage: int
    hp_regen: float
    has_died: bool
    cooldown: int
    experience: int
    cannon_angle: float
    """ degrees """

    upgrade_tokens: int
    upgrade_levels: Upgrades
