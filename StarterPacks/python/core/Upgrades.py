from dataclasses import dataclass
from enum import Enum


class Upgrade(Enum):
    """
    Upgrades that you can do to a tank.
    """
    SPEED_UPGRADE = "speed"
    FIRE_RATE_UPGRADE = "fire_rate"
    PROJECTILE_DAMAGE = "projectile_damage"
    MAX_HP_UPGRADE = "max_hp"
    BODY_DAMAGE_UPGRADE = "body_damage"
    HP_REGEN = "hp_regen"
    PROJECTILE_TIME_TO_LIVE = "projectile_time_to_live"
    PROJECTILE_SPEED = "projectile_speed"

    def __str__(self):
        return self.value


@dataclass()
class UpgradeRates:
    """
    Rates at which an upgrade boost the stats of a tank. Ex if body_damage rate is 1.20 and
    you have 50 body damage, upgrading it will result in 50 * 1.20 = 60 body damage.
    """

    body_damage: float
    fire_rate: float
    max_hp: float
    speed: float
    projectile_damage: float
    hp_regen: float
    projectile_time_to_live: float
    projectile_speed: float


@dataclass()
class Upgrades:
    """
    Upgrades a tank has done to itself. Does not represent the raw values but the number of times
    it has been upgraded. Ex if max_hp == 3, a tank has upgraded its max HP three times.
    """
    max_hp: int
    speed: int
    fire_rate: int
    projectile_damage: int
    body_damage: int
    hp_regen: int
    projectile_time_to_live: int
    projectile_speed: int
