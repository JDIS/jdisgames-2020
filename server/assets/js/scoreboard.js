import Vue from "vue";
import Scoreboard from "./scoreboard.vue";

const scoreboard = new Vue({
    render: h => h(Scoreboard)
}).$mount("#scoreboard")