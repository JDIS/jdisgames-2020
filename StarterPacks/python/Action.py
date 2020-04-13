from dataclasses import dataclass
from typing import Tuple

from Upgrades import Upgrade


@dataclass()
class Action:
    """
    Actions that a bot makes every tick. move to *destination*, shoot a projectile to *target* or
    buy *purchase*. If you specify something that cannot be done (like shooting when your cannon
    is on cooldown), it acts as a NOOP but other actions succeed.
    """

    destination: Tuple[int, int]
    target: Tuple[int, int]
    purchase: Upgrade
