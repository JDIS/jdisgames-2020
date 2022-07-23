<template>
  <form class="game-settings" method="POST">
    <input type="hidden" name="_csrf_token" v-model="csrfToken" />
    <input type="hidden" name="game_name" v-model="game_name" />
    <p class="game-settings-title">{{ game_title }}</p>
    <label class="label-input-wrapper">
      Number of ticks:
      <input type="number" name="ticks" v-model="ticks" min="1" />
    </label>
    <label class="label-input-wrapper">
      Max debris count:
      <input type="number" name="max_debris_count" v-model="debris_count" min="1" />
    </label>
    <label class="label-input-wrapper">
      Debris generation rate:
      <input type="number" name="max_debris_generation_rate" v-model="debris_generation_rate" min="0" max="1" step="0.01" />
    </label>
    <label class="label-input-wrapper">
      Score multiplier:
      <input type="number" name="score_multiplier" v-model="score_multiplier" min="1" step="0.01" />
    </label>
    <fieldset>
      <legend>Upgrade parameters</legend>
      <table class="upgrade-params-table">
        <thead>
          <tr>
            <th></th>
            <th>Base value</th>
            <th>Upgrade rate</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(upgradeParams, upgradeName) in upgrade_params">
            <th>{{ upgradeName.replace(/_/g, ' ') }}</th>
            <td><input type="number" step="0.01" :name="`upgrade_params[${upgradeName}][baseValue]`" v-model="upgradeParams.baseValue" /></td>
            <td><input type="number" step="0.01" :name="`upgrade_params[${upgradeName}][upgradeRate]`" v-model="upgradeParams.upgradeRate" /></td>
          </tr>
        </tbody>
      </table>
    </fieldset>
    <button type="submit" formaction="/admin/save">Save</button>
    <button type="submit" formaction="/admin/start">Start</button>
    <button type="submit" formaction="/admin/stop">Stop</button>
    <button type="submit" formaction="/admin/kill">Kill</button>
  </form>
</template>

<script>
export default {
  name: "GameSettings",
  data() {
    return {
      debris_count: this.$props.params.maxDebrisCount,
      debris_generation_rate: this.$props.params.maxDebrisGenerationRate,
      ticks: this.$props.params.numberOfTicks,
      score_multiplier: this.$props.params.scoreMultiplier,
      upgrade_params: {
        speed: this.$props.params.upgradeParams.speed,
        max_hp: this.$props.params.upgradeParams.max_hp,
        projectile_damage: this.$props.params.upgradeParams.projectile_damage,
        body_damage: this.$props.params.upgradeParams.body_damage,
        fire_rate: this.$props.params.upgradeParams.fire_rate,
        hp_regen: this.$props.params.upgradeParams.hp_regen,
        projectile_time_to_live: this.$props.params.upgradeParams.projectile_time_to_live,
      }
    };
  },
  props: ["game_title", "game_name", "params", "csrfToken"],
  watch: {},
  computed: {},
  mounted() {},
  methods: {}
};
</script>

