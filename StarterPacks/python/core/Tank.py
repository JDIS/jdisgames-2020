from dataclasses import dataclass
from typing import Tuple, Optional

from core.Upgrades import Upgrades


@dataclass()
class Tank:
    """
    Represents a tank (you or enemy) and all its stats.
    """
    id: int
    name: str
    max_hp: int
    current_hp: float
    speed: int
    """ x, y """
    position: Tuple[int, int]
    direction: Optional[Tuple[int, int]]
    target: Optional[Tuple[int, int]]

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

    projectile_time_to_live: int
    upgrade_tokens: int
    upgrade_levels: Upgrades
    has_triple_gun: bool
    ticks_alive: int
