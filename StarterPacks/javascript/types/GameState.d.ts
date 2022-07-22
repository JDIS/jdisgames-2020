import type Tank from './Tank'
import type Debris from './Debris'
import type Projectile from './Projectile'
import type Clock from './Clock'
import type { UpgradeParams } from './Upgrades'
import type HotZone from './HotZone'

export default interface GameState {
  name: string
  // The key is the tank ID and the value is the tank
  tanks: Record<number, Tank>
  debris: Debris[]
  projectiles: Projectile[]
  map_width: number
  map_height: number
  clock: Clock
  upgrade_params: UpgradeParams
  game_id: number
  /* True if it is the ranked game (the one where points count). You can use this to introduce
    changes in the code but only test them in the unranked game. */
  is_ranked: boolean
  hot_zone: HotZone
}