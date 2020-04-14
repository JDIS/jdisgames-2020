from dataclasses import dataclass
from typing import Dict, List

from core.Clock import Clock
from core.Debris import Debris
from core.Projectile import Projectile
from core.Tank import Tank
from core.Upgrades import UpgradeRates


@dataclass()
class GameState:
    name: str

    tanks: Dict[int, Tank]
    """ The key is the tank ID and the value is the tank"""

    debris: List[Debris]
    projectiles: List[Projectile]
    map_width: int
    map_height: int
    clock: Clock

    upgrade_rates: UpgradeRates
    game_id: int
    is_ranked: bool
    """
    True if it is the ranked game (the one where points count). You can use this to introduce
    changes in the code but only test them in the unranked game.
    """
