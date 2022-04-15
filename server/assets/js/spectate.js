import { createApp } from "vue";
import Spectate from "./spectate.vue";
import { networkInit } from "./modules/network"

const app = createApp(Spectate).mount("#app")

export default app

const game_name = new URLSearchParams(window.location.search).get("game_name");
networkInit(game_name)