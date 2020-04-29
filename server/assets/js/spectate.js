import Vue from "vue";
import Spectate from "./spectate.vue";
import { networkInit } from "./modules/network"

const app = new Vue({
    render: h => h(Spectate)
}).$mount("#app")

export default app.$children[0]

const game_name = new URLSearchParams(window.location.search).get("game_name");
networkInit(game_name)