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

    def __str__(self):
        return self.value


@dataclass()
class UpgradeProperties:
    """
    Parameters governing how upgradable stats are calculated.

    base_value: The stat value when upgrade is at level 0.

    upgrade_rate: Rate at which an upgrade boost the stats of a tank.
    """

    base_value: float
    upgrade_rate: float


@dataclass()
class UpgradeParams:
    body_damage: UpgradeProperties
    fire_rate: UpgradeProperties
    max_hp: UpgradeProperties
    speed: UpgradeProperties
    projectile_damage: UpgradeProperties
    hp_regen: UpgradeProperties
    projectile_time_to_live: UpgradeProperties


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
