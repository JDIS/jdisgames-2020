from dataclasses import dataclass
from typing import Tuple


@dataclass()
class Action:
    """
    Actions that a bot makes every tick.
    """
    destination: Tuple[float]
