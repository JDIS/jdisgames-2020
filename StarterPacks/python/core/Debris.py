from dataclasses import dataclass
from enum import Enum
from typing import Tuple


class DebrisType(Enum):
    SMALL = "small"
    MEDIUM = "medium"
    LARGE = "large"


@dataclass()
class Debris:
    """ Debris in the map to be destroyed for points and experience """

    id: str
    current_hp: int
    max_hp: int
    size: DebrisType
    position: Tuple[int, int]
    """ x, y """
