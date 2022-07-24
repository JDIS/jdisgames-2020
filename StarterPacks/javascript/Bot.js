const upgrades = require("./core/Upgrades")

class Bot {
  constructor(id) {
    this.id = id
  }

  randomUpgrade() {
    const upgradeNames = Object.values(upgrades)
    return upgradeNames[Math.floor(Math.random() * upgradeNames.length)];
  }

  randomPosition(state) {
    return [Math.floor(Math.random() * state.map_width), Math.floor(Math.random() * state.map_height)]
  }

  tick(state) {
    // Program your bot here

    return {
      destination: this.randomPosition(state),
      target: this.randomPosition(state),
      purchase: this.randomUpgrade()
    }
  }
}

module.exports = Bot
