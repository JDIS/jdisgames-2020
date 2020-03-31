<template>
    <div>
        <h1>Admin</h1>
        Number of ticks: <input type="number" v-model="ticks" min="1" />
        <button @click="startGame()">Start</button>
        <button @click="stopGame()">Stop</button>
    </div>
</template>

<script>
    import Vue from "vue"
    import axios from "axios"

    export default Vue.extend({
        name: 'Admin',
        data() {
            return {
                ticks: 500
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
            }
        }
    })
</script>

