const { program } = require('commander');
const Bot = require('./Bot')
const { Socket } = require("phoenix")
require('websocket-polyfill')

const DEFAULT_BASE_URL = "wss://jdis-ia.dinf.usherbrooke.ca/socket"
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

async function initializeChannel(socketEndpoint, socketOptions, channelTopic, backendUrl) {
  return new Promise((resolve) => {
    const url = `${backendUrl}/${socketEndpoint}`
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

async function initializeActionChannel(secret, isRanked, backendUrl) {
  const channel = await initializeChannel('bot', { params: { secret }}, `action:${getGameName(isRanked)}`, backendUrl)
  channel.onError((reason) => {
    console.error(`Channel encountered an error: ${JSON.stringify(reason)}`);
    process.exit();
  })
  return channel
}

async function initializeGameStateChannel(isRanked, backendUrl) {
  return await initializeChannel('spectate', { }, `game_state:${getGameName(isRanked)}`, backendUrl)
}

async function start({ secret, isRanked, backendUrl }) {
  const [actionChannel, gameStateChannel] = await Promise.all([
    initializeActionChannel(secret, isRanked, backendUrl),
    initializeGameStateChannel(isRanked, backendUrl)
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
  .option('-r, --no-ranked', 'Connects to the secondary game instead of the ranked one')
  .option('-u, --backend_url <url>', 'The url of the backend server', DEFAULT_BASE_URL)

program.parse()

const options = program.opts()

start({ secret: options.secret, isRanked: options.ranked, backendUrl: options.backend_url })
