//import {mockNetworkInit} from "./mock.js"
import { Socket } from "phoenix"
import app from "../spectate"

export function networkInit() {
    let socket = new Socket("/socket/spectate")

    socket.connect()

    let gameStateChannel = socket.channel("game_state", {})

    gameStateChannel.join()
        .receive("ok", resp => { console.log("Joined game_state successfully", resp) })
        .receive("error", resp => { console.log("Unable to join game_state", resp) })
    let yes = false
    gameStateChannel.on("new_state", resp => {
        if (!yes) {
            yes = true
            app.startRendering(resp)
        } else {
            app.animateCanvas(resp)
        }
    })
}
