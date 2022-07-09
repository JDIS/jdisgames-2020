<template>
  <div class="game-settings-wrapper">
    <div class="game-settings">
      <p class="game-settings-title">{{ game_title }}</p>
      <div class="label-input-wrapper">
        <label for="main-game-ticks">Number of ticks:</label>
        <input id="main-game-ticks" type="number" v-model="ticks" min="1" />
      </div>
      <div class="label-input-wrapper">
        <label for="main-game-debris-count">Max debris count:</label>
        <input id="main-game-debris-count" type="number" v-model="debris_count" min="1" />
      </div>
      <div class="label-input-wrapper">
        <label for="main-game-debris-rate">Debris generation rate:</label>
        <input id="main-game-debris-rate" type="number" v-model="debris_generation_rate" min="0" max="1" step="0.01" />
      </div>
      <div class="label-input-wrapper">
        <label for="main-game-score-multiplier">Score multiplier:</label>
        <input id="main-game-score-multiplier" type="number" v-model="score_multiplier" min="1" step="0.01" />
      </div>
      <button @click="saveParams()">Save</button>
      <button @click="startGame()">Start</button>
      <button @click="stopGame()">Stop</button>
      <button @click="killGame()">Kill</button>
    </div>
  </div>
</template>

<script>
export default {
  name: "GameSettings",
  data() {
    return {
      debris_count: this.$props.params.maxDebrisCount,
      debris_generation_rate: this.$props.params.maxDebrisGenerationRate,
      ticks: this.$props.params.numberOfTicks,
      score_multiplier: this.$props.params.scoreMultiplier
    };
  },
  props: ["game_title", "game_name", "params"],
  watch: {},
  computed: {},
  mounted() {},
  methods: {
    saveParams() {
      const params = {
        ticks: this.ticks,
        max_debris_count: this.debris_count,
        max_debris_generation_rate: this.debris_generation_rate,
        game_name: this.$props.game_name,
        score_multiplier: this.score_multiplier
      };
      const searchParams = new URLSearchParams(params);
      window.location = `/admin/save?${searchParams.toString()}`;
    },
    startGame() {
      const params = {
        game_name: this.$props.game_name,
      };
      const searchParams = new URLSearchParams(params);
      window.location = `/admin/start?${searchParams.toString()}`;
    },

    stopGame() {
      window.location = `/admin/stop?game_name=${this.$props.game_name}`;
    },

    killGame() {
      window.location = `/admin/kill?game_name=${this.$props.game_name}`;
    }
  }
};
</script>

