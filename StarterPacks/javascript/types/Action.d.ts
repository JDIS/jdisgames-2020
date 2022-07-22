import type { Upgrade } from "./Upgrades"

export default interface Action {
  /*
    Actions that a bot makes every tick. move to *destination*, shoot a projectile to *target* or
    buy *purchase*. If you specify something that cannot be done (like shooting when your cannon
    is on cooldown), it acts as a NOOP but other actions succeed.
  */

  destination: [number, number]
  target: [number, number]
  purchase: Upgrade
}
