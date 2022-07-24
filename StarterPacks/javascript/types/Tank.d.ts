import type { Upgrades } from './Upgrades'

export default interface Tank {
  id: number
  name: string
  max_hp: number
  current_hp: number
  speed: number
  position: [number, number]
  destination?: [number, number]
  target?: [number, number]
  score: number
  fire_rate: number
  projectile_damage: number
  body_damage: number
  hp_regen: number
  has_died: boolean
  cooldown: number
  experience: number
  cannon_angle: number
  projectile_time_to_live: number
  upgrade_tokens: number
  upgrade_levels: Upgrades
  has_triple_gun: boolean
  ticks_alive: number
}