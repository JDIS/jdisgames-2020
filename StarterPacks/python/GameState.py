from dataclasses import dataclass
from typing import Dict, List

from Debris import Debris
from Projectile import Projectile
from Tank import Tank
from Upgrades import UpgradeRates


@dataclass()
class GameState:
    name: str

    tanks: Dict[int, Tank]
    """ The key is the tank ID and the value is the tank"""

    debris: List[Debris]
    projectiles: List[Projectile]
    map_width: int
    map_height: int
    ticks: int
    """ tick number for the current game """
    max_ticks: int
    """ max ticks before the game ends """

    upgrade_rates: UpgradeRates
    game_id: int
    is_ranked: bool
    """
    True if it is the ranked game (the one where points count). You can use this to introduce
    changes in the code but only test them in the unranked game.
    """



