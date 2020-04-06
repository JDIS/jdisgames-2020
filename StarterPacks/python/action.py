from dataclasses import dataclass
from typing import Tuple


@dataclass()
class Action:

    SPEED_UPGRADE = "speed"
    FIRE_RATE_UPGRADE = "fire_rate"
    PROJECTILE_DAMAGE = "projectile_damage"
    MAX_HP_UPGRADE = "max_hp"
    BODY_DAMAGE_UPGRADE = "body_damage"

    """
    Actions that a bot makes every tick.
    """
    destination: Tuple[float, float]
    target: Tuple[float, float]
    purchase: str
