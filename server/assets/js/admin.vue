<template>
  <div>
    <h1>Admin</h1>
    <div id="game-settings-container">
      <GameSettings game_title="Main game" game_name="main_game" :params="gameParams.main" />
      <GameSettings game_title="Secondary game" game_name="secondary_game" :params="gameParams.secondary" />
    </div>
  </div>
</template>

<script>
import GameSettings from "./game_settings.vue";

export default {
  name: "Admin",
  data() {
    return {};
  },
  props: ["gameParams"],
  watch: {},
  computed: {},
  mounted() {},
  methods: {},
  components: {
    GameSettings
  }
};
</script>

