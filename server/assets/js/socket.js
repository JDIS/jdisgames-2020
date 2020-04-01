import { Socket, SocketConnectOption } from "phoenix"

let options = {decode: function(rawPayload, callback) {
  let [join_ref, ref, topic, event, payload] = JSON.parse(rawPayload, (key, value) => {
    if (key === "id" && typeof(value) == "string") {
      return BigInt(value)
    }
    return value
})

    return callback({join_ref, ref, topic, event, payload})
}}
let spectateSocket = new Socket("/socket/spectate", options)

spectateSocket.connect()

// Now that you are connected, you can join channels with a topic:
let gameStateChannel = spectateSocket.channel("game_state", {})

gameStateChannel.join()
  .receive("ok", resp => { console.log("Joined game_state successfully", resp) })
  .receive("error", resp => { console.log("Unable to join game_state", resp) })

gameStateChannel.on("new_state", resp => { console.log(resp) })

export default socket
