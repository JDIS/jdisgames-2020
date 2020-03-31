import Vue from "vue";
import Admin from "./admin.vue";

const admin = new Vue({
    render: h => h(Admin)
}).$mount("#admin")