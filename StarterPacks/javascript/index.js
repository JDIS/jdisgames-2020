const { program } = require('commander');
const Bot = require('./Bot')
const { Socket } = require("phoenix")
require('websocket-polyfill')

const BASE_URL = "ws://127.0.0.1:4000/socket"
const MIN_TICKS_PER_SECOND = 3

const q = require('queue')({ autostart: true, concurrency: 1, timeout: 1000 / MIN_TICKS_PER_SECOND })

function getGameName(isRanked) {
  if (isRanked) {
    return 'main_game'
  }

  return 'secondary_game'
}

function handleError(e) {
  console.error(e)
  process.exit()
}

function handleChannelPayload(rawPayload, callback) {
  const [join_ref, ref, topic, event, payload] = JSON.parse(rawPayload, (key, value) => {
    if (key === "id" && typeof (value) == "string") {
      return BigInt(value)
    }
    return value
  })

  return callback({ join_ref, ref, topic, event, payload })
}

async function initializeChannel(socketEndpoint, socketOptions, channelTopic) {
  return new Promise((resolve) => {
    const url = `${BASE_URL}/${socketEndpoint}`
    const socket = new Socket(url, socketOptions)
    socket.onError(handleError)
    socket.connect()

    const channel = socket.channel(channelTopic)

    channel
      .join()
      .receive('ok', () => {
        console.log(`Successfully joined channel ${channel.topic}`)
        resolve(channel)
      })
      .receive('error', handleError)
      .receive('timeout', handleError)
  })
}

async function initializeActionChannel(secret, isRanked) {
  return await initializeChannel('bot', { params: { secret }}, `action:${getGameName(isRanked)}`)
}

async function initializeGameStateChannel(isRanked) {
  return await initializeChannel('spectate', { decode: handleChannelPayload }, `game_state:${getGameName(isRanked)}`)
}

async function start({ secret, isRanked }) {
  const [actionChannel, gameStateChannel] = await Promise.all([
    initializeActionChannel(secret, isRanked),
    initializeGameStateChannel(isRanked)
  ])

  actionChannel.push("get_id").receive('ok', ({ id }) => {
    const bot = new Bot(id)
    
    gameStateChannel.on('new_state', (state) => {
      if (q.length > 0) {
        q.shift(0, q.length - 1)
      }
      q.push(() => {
        const action = bot.tick(state)
        actionChannel.push("new", action)
      })
    })
  })
}

program
  .requiredOption('-s, --secret <secret>', 'The secret which authenticates your bot')
  .option('-r, --is_ranked', 'Whether the bot should connect to the ranked game (true) or the practice one (false)', true)

program.parse()

const options = program.opts()

start({ secret: options.secret, isRanked: options.is_ranked })
