export default interface Projectile {
  /*
    Represents an active projectile on the map
  */

  id: number
  owner_id: number
  radius: number
  speed: number
  damage: number
  angle: number
  // number of iterations before the projectile disappears
  time_to_live: number

  // x, y
  position: [number, number]
}
