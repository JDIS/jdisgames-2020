from dataclasses import dataclass


@dataclass()
class Clock:
    current_tick: int
    """ tick number for the current game """
    max_tick: int
    """ max ticks before the game ends """
