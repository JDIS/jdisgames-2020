const upgrades = require("./core/Upgrades")

class Bot {
  constructor(id) {
    this.id = id
  }

  distanceFrom(debris) {
    return Math.sqrt(Math.pow(this.tank.position[0] - debris.position[0], 2) + Math.pow(this.tank.position[1] - debris.position[1], 2))
  }

  findNearestDebris(state) {
    return [...state.debris].sort((a, b) => {
      const distanceA = this.distanceFrom(a)
      const distanceB = this.distanceFrom(b)

      return distanceA > distanceB ? 1 : -1
    })[0]
  }

  destinationTo(debris) {
    return [debris.position[0], debris.position[1] + 160]
  }

  randomUpgrade() {
    const upgradeNames = Object.values(upgrades)
    return upgradeNames[Math.floor(Math.random() * upgradeNames.length)];
  }

  tick(state) {
    // Program your bot here
    this.tank = state.tanks[this.id]
    const nearestDebris = this.findNearestDebris(state)

    return {
      destination: this.destinationTo(nearestDebris),
      target: nearestDebris.position,
      purchase: this.randomUpgrade()
    }
  }
}

module.exports = Bot
