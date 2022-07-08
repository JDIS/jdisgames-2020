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
  
  return {
    numberOfTicks: parseInt(element.getAttribute("data-number-of-ticks")),
    maxDebrisCount: parseInt(element.getAttribute("data-max-debris-count")),
    maxDebrisGenerationRate: parseFloat(element.getAttribute("data-max-debris-generation-rate")),
    scoreMultiplier: parseFloat(element.getAttribute("data-score-multiplier")),
  }
}

const mainGameParamsElement = document.getElementById("mainGameParams")
const secondaryGameParamsElement = document.getElementById("secondaryGameParams")

const props = {
  gameParams: {
    main: getGameSettings(mainGameParamsElement),
    secondary: getGameSettings(secondaryGameParamsElement)
  }
}

createApp(Admin, props).mount("#admin");
