<template>
  <div class="game-settings-wrapper">
    <div class="game-settings">
      <p class="game-settings-title">{{ game_title }}</p>
      <div class="label-input-wrapper">
        <label class="game-time-label" for="main-game-ticks">Number of ticks:</label>
        <input id="main-game-ticks" class="game-time-input" type="number" v-model="ticks" min="1" />
      </div>
      <button @click="startGame()">Start</button>
      <button @click="stopGame()">Stop</button>
      <button @click="killGame()">Kill</button>
    </div>
  </div>
</template>

<script>
import Vue from "vue";
import axios from "axios";

export default Vue.extend({
  name: "GameSettings",
  data() {
    return {
      ticks: 2000
    };
  },
  props: ["game_title", "game_name"],
  watch: {},
  computed: {},
  mounted() {},
  methods: {
    startGame() {
      window.location = `/admin/start?ticks=${this.ticks}&game_name=${this.$props.game_name}`;
    },

    stopGame() {
      window.location = `/admin/stop?game_name=${this.$props.game_name}`;
    },

    killGame() {
      window.location = `/admin/kill?game_name=${this.$props.game_name}`;
    }
  }
});
</script>

