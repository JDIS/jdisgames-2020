<template>
    <div>
        <h1>Admin</h1>
        Number of ticks: <input type="number" v-model="ticks" min="1" />
        <button @click="startGame()">Start</button>
        <button @click="stopGame()">Stop</button>
        <button @click="killGame()">Kill</button>
    </div>
</template>

<script>
    import Vue from "vue"

    export default Vue.extend({
        name: 'Admin',
        data() {
            return {
                ticks: 2000
            }
        },
        watch: {
        },
        computed: {

        },
        mounted() {

        },
        methods: {
            startGame() {
                window.location = `/admin/start?ticks=${this.ticks}`
            },

            stopGame() {
                window.location = '/admin/stop'
            },

            killGame() {
                window.location = '/admin/kill'
            }
        }
    })
</script>

