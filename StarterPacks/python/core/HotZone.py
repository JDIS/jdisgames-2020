from dataclasses import dataclass
from typing import Tuple


@dataclass
class HotZone:
	position: Tuple[int, int]
	radius: int
