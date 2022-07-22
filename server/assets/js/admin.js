import { createApp } from "vue";
import Admin from "./admin.vue";

function getGameSettings(element) {
  if (element === null) {
    return {
      numberOfTicks: 2000,
      maxDebrisCount: 400,
      maxDebrisGenerationRate: 0.15,
      scoreMultiplier: 1,
    }
  }

  const upgradeParams = [
    "speed",
    "max_hp",
    "projectile_damage",
    "body_damage",
    "fire_rate",
    "hp_regen",
    "projectile_time_to_live",
  ].reduce((acc, stat) => {
    acc[stat] = {
      baseValue: parseFloat(element.getAttribute(`data-upgrade-base_value-${stat}`)),
      upgradeRate: parseFloat(element.getAttribute(`data-upgrade-upgrade_rate-${stat}`))
    }
    return acc;
  }, {})
  
  return {
    numberOfTicks: parseInt(element.getAttribute("data-number-of-ticks")),
    maxDebrisCount: parseInt(element.getAttribute("data-max-debris-count")),
    maxDebrisGenerationRate: parseFloat(element.getAttribute("data-max-debris-generation-rate")),
    scoreMultiplier: parseFloat(element.getAttribute("data-score-multiplier")),
    upgradeParams
  }
}

const mainGameParamsElement = document.getElementById("mainGameParams")
const secondaryGameParamsElement = document.getElementById("secondaryGameParams")

const props = {
  gameParams: {
    main: getGameSettings(mainGameParamsElement),
    secondary: getGameSettings(secondaryGameParamsElement)
  },
  csrfToken: document.getElementById("admin").getAttribute("data-csrf-token"),
  globalParams: {
    enableScoreboardAuth: JSON.parse(document.getElementById("admin").getAttribute("data-enable-scoreboard-auth"))
  }
}

createApp(Admin, props).mount("#admin");
