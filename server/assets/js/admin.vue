<template>
  <div>
    <h1>Admin</h1>
    <div id="game-settings-container">
      <GameSettings game_title="Main game" game_name="main_game" :params="gameParams.main" :csrfToken="csrfToken" />
      <GameSettings game_title="Secondary game" game_name="secondary_game" :params="gameParams.secondary" :csrfToken="csrfToken" />

      <form class="game-settings" method="POST" action="/admin/save-global">
        <p class="game-settings-title">Global params</p>
        <input type="hidden" name="_csrf_token" v-model="csrfToken" />
        <label class="label-input-wrapper">
          Enable scoreboard auth
          <input type="checkbox" name="enable_scoreboard_auth" v-model="enable_scoreboard_auth" />
        </label>
        <button type="submit">Save</button>
      </form>
    </div>
  </div>
</template>

<script>
import GameSettings from "./game_settings.vue";

export default {
  name: "Admin",
  data() {
    return {
      enable_scoreboard_auth: this.$props.globalParams.enableScoreboardAuth
    };
  },
  props: ["gameParams", "csrfToken", "globalParams"],
  watch: {},
  computed: {},
  mounted() {},
  methods: {},
  components: {
    GameSettings
  }
};
</script>

