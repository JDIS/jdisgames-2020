import { Socket } from "phoenix"

window.userToken = "c3879428-8e7d-4713-a598-b88c7d2f05e9"
let socket = new Socket("/socket/bot", { params: { secret: window.userToken } })
let spectateSocket = new Socket("/socket/spectate")

socket.connect()
spectateSocket.connect()

// Now that you are connected, you can join channels with a topic:
let actionChannel = socket.channel("action", {})
let gameStateChannel = spectateSocket.channel("game_state", {})

let xInput = document.querySelector("#x")
let yInput = document.querySelector("#y")
let sendButton = document.querySelector("#send-button")

sendButton.addEventListener("click", function (_event) {
  actionChannel.push("new", {
    tank_id: 7,
    destination: [parseInt(xInput.value), parseInt(yInput.value)],
    target: null,
    purchase: null
  })

  xInput.value = 0
  yInput.value = 0
})

actionChannel.join()
  .receive("ok", resp => { console.log("Joined action successfully", resp) })
  .receive("error", resp => { console.log("Unable to join action", resp) })

gameStateChannel.join()
  .receive("ok", resp => { console.log("Joined game_state successfully", resp) })
  .receive("error", resp => { console.log("Unable to join game_state", resp) })

gameStateChannel.on("new_state", resp => { console.log(resp) })

export default socket
