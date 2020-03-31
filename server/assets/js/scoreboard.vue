<template>
    <div>
        <h1>Scoreboard</h1>

        <label for="log">Logarithmic Scale</label> <input id="log" type="checkbox" v-model="logScale" />

        <div style="position: relative;">
            <canvas id="scoreboard-chart" width="400" height="400"></canvas>
        </div>
    </div>
</template>

<script>
    import Vue from "vue"
    import axios from "axios"
    import Chart from "chart.js"
    import {COLORS} from "./modules/constants";

    export default Vue.extend({
        name: 'Scoreboard',
        data() {
            return {
                scores: [],
                chart: null,
                logScale: false
            }
        },
        watch: {
          logScale(previousValue, newValue) {
              if (newValue) {
                  this.chart.options.scales.yAxes[0].type = 'linear'
              } else {
                  this.chart.options.scales.yAxes[0].type = 'logarithmic'
              }
              this.chart.update()
          }
        },
        computed: {
            sortedScores() {
              return this.scores.sort((a, b) => a.game_id < b.game_id ? -1 : 1)
            },
            uniqueGameId() {
                const unique = new Set()
                this.scores.forEach(score => unique.add(score.game_id))
                return Array.from(unique)
            },
            uniqueUserId() {
                const unique = new Set()
                this.scores.forEach(score => unique.add(score.user_id))
                return Array.from(unique)
            }
        },
        mounted() {
            axios.get("/api/scoreboard").then(({data}) => {
                this.scores = data.scores
                const ctx = document.getElementById('scoreboard-chart').getContext('2d');
                const datasets = {}
                this.uniqueUserId.forEach(id => {
                    datasets[id] = {
                        data: [],
                        borderWidth: 1,
                        fill: false
                    }
                })
                this.sortedScores.forEach(score => {
                    datasets[score.user_id]["label"] = score.user_id
                    if(datasets[score.user_id]["data"].length < 1) {
                        datasets[score.user_id]["data"]
                            .push(score.score)
                    } else {
                        datasets[score.user_id]["data"]
                            .push(score.score + datasets[score.user_id]["data"][datasets[score.user_id]["data"].length - 1])
                    }
                    datasets[score.user_id]["borderColor"] = COLORS[score.user_id % COLORS.length]
                })
                this.chart = new Chart(ctx, {
                    type: 'line',
                    data: {
                        labels: Array.from(Array(this.uniqueGameId.length).keys()),
                        datasets: Object.values(datasets)
                    },
                    options: {
                        maintainAspectRatio: false,
                        scales: {
                            yAxes: [{
                                type: 'linear',
                                ticks: {
                                    beginAtZero: true
                                }
                            }]
                        }
                    }
                });
            })
        },
        methods: {

        }
    })
</script>

