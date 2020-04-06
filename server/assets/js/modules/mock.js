/**
 * Module to deal with mocking logic to fake game updates if we don't have a server to test with.
 */

import app from "../spectate"
import {CANVAS_UPDATE_RATE, COLORS, MAP_HEIGHT, MAP_WIDTH} from "./constants.js"

export function mockNetworkInit() {
    window.setInterval(() => {
        const newState = generateNextFrame(app.elements.players, app.progress, app.elements.projectiles, app.elements.debris)
        if (document.visibilityState === "visible") {
            app.animateCanvas(JSON.parse(newState))
        }
    }, CANVAS_UPDATE_RATE)
}
export function generatePlayers() {
    const players = []
    for (let i = 0; i < 30; i++) {
        const tank = {
            name: `😎${i}`,
            id: i,
            position: [Math.random() * MAP_WIDTH, Math.random() * MAP_HEIGHT],
            angle: Math.random() * 360,
            health: Math.random(),
            fillColor: COLORS[i % COLORS.length],
            points: Math.random() * 1000
        }
        players.push(tank)
    }
    return players

}
export function generateSampleMap() {

    const gameState = {
        progress: Math.random(),
        players: [],
        debris: []
    }

    gameState.players = generatePlayers()

    for (let i = 0; i < 700; i++) {
        const debris = {
            id: Math.round(Math.random() * 50000000000000).toString(),
            type: 1,
            position: [Math.random() * MAP_WIDTH, Math.random() * MAP_HEIGHT],
            health: Math.random(),
        }
        gameState.debris.push(debris)
    }

    for (let i = 0; i < 100; i++) {
        const debris = {
            id: i.toString(),
            type: 2,
            position: [Math.random() * MAP_WIDTH, Math.random() * MAP_HEIGHT],
            health: Math.random(),
        }
        gameState.debris.push(debris)
    }


    return JSON.stringify(gameState)
}
export function generateNextFrame(players, progress, projectiles, debris) {
    const newProjectiles = []
    const newPlayers = []
    for (let i = 0; i < players.length; i++) {
        const newPlayer = {}
        newPlayer.id = players[i].id
        newPlayer.name = players[i].name
        newPlayer.health = Math.random()
        newPlayer.position = players[i].position
        newPlayer.angle = Math.random() * 360
        newPlayer.points = players[i].points + (Math.random() * 100)
        newPlayer.fillColor = players[i].fillColor
        newPlayer.position[0] = newPlayer.position[0] + (Math.sin(Math.random() * 2 * 3.14159) * 60)
        newPlayer.position[1] = newPlayer.position[1] + (Math.sin(Math.random() * 2 * 3.14159) * 60)

        if (Math.random() < 0.2) {
            newProjectiles.push({
                id: Math.round(Math.random() * 500000000000).toString(),
                position: [newPlayer.position[0] + 100, newPlayer.position[1] + 60],
                fillColor: newPlayer.fillColor,
                belongsTo: newPlayer.id,

            })
        }

        newPlayers.push(newPlayer)
    }

    Object.keys(projectiles).map((id) => {
        if (Math.random() < 0.7) {
            newProjectiles.push({
                belongsTo: projectiles[id].belongsTo,
                fillColor: projectiles[id].fill,
                position: [projectiles[id].left + 100, projectiles[id].top + 60],
                id: id
            })
        }
    })

    const newDebris = []
    Object.keys(debris).map((id) => {
        if (Math.random() < 0.99) {
            newDebris.push({
                id: id,
                type: debris[id].type,
                position: [debris[id].left, debris[id].top],
                health: debris[id].health,
            })
        }
    })

    for (let i = 0; i < 800; i++) {
        if (Math.random() >= 0.99) {
            newDebris.push({
                id: Math.round(Math.random() * 50000000000000).toString(),
                type: Math.random() > 7/8 ? 2 : 1,
                position: [Math.random() * MAP_WIDTH, Math.random() * MAP_HEIGHT],
                health: Math.random()
            })
        }
    }

    return JSON.stringify({
        progress: (progress + 0.003) % 1,
        players: newPlayers,
        projectiles: newProjectiles,
        debris: newDebris
    })
}
