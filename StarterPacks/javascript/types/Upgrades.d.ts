export enum Upgrade {
  /*
    Upgrades that you can do to a tank.
  */

  SPEED_UPGRADE = "speed",
  FIRE_RATE_UPGRADE = "fire_rate",
  PROJECTILE_DAMAGE = "projectile_damage",
  MAX_HP_UPGRADE = "max_hp",
  BODY_DAMAGE_UPGRADE = "body_damage",
  HP_REGEN = "hp_regen",
  PROJECTILE_TIME_TO_LIVE = "projectile_time_to_live",
}

export interface UpgradeProperties {
  // The stat value when upgrade is at level 0:
  base_value: number
  // Rate at which an upgrade boost the stats of a tank.
  upgrade_rate: number
}

export interface UpgradeParams {
  body_damage: UpgradeProperties
  fire_rate: UpgradeProperties
  max_hp: UpgradeProperties
  speed: UpgradeProperties
  projectile_damage: UpgradeProperties
  hp_regen: UpgradeProperties
  projectile_time_to_live: UpgradeProperties
}

export interface Upgrades {
  /*
    Upgrades a tank has done to itself. Does not represent the raw values but the number of times
    it has been upgraded. Ex if max_hp == 3, a tank has upgraded its max HP three times.
  */

  max_hp: number
  speed: number
  fire_rate: number
  projectile_damage: number
  body_damage: number
  hp_regen: number
  projectile_time_to_live: number
}
