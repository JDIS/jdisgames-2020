import Vue from 'https://cdn.jsdelivr.net/npm/vue@2.6.0/dist/vue.esm.browser.js'
import {
    ANIMATION_DURATION,
    CANVAS_UPDATE_RATE,
    HEALTH_OFFSET,
    HEALTHBAR_WIDTH,
    linear,
    MAX_ZOOM,
    MIN_ZOOM,
    NAME_OFFSET,
    SELECTED_TANK_OUTLINE_COLOR
} from "./modules/constants.mjs"
import {createHealthBar, generateSampleMap} from "./modules/mock.mjs"
import {
    createDebris1,
    createDebris2,
    createGrid,
    createMinimap,
    createProjectile,
    createTank,
    DrawnElements,
    initFabricCreateMinimap
} from "./modules/canvas.mjs"
import {getDifference} from "./modules/utils.mjs"
import {networkInit} from "./modules/network.mjs"

export default new Vue({
    el: '#app',
    data: {
        zoom: 0.45,
        focusedPlayer: null,
        mainCanvas: null,
        minimap: null,
        lockCamera: false,
        elements: new DrawnElements(null, null, [], {}, {}),
        progress: 0,
        autoSpectate: false,
        lastUpdateTimestamp: Date.now()
    },
    computed: {
        /**
         * @returns List of players ordered by their score in the current game.
         */
        orderedPlayers() {
            return this.elements.players.sort((a, b) => a.points < b.points ? 1 : -1)
        }
    },
    watch: {
        focusedPlayer(newValue, previousValue) {
            if (previousValue) {
                previousValue.tank.item(0).stroke = 'black'
                previousValue.tank.item(0).strokeWidth = 3
                previousValue.tank.item(1).stroke = 'black'
                previousValue.tank.item(1).strokeWidth = 3
                previousValue.tank.dirty = true // Invalidate caching
            }
            newValue.tank.item(0).stroke = SELECTED_TANK_OUTLINE_COLOR
            newValue.tank.item(0).strokeWidth = 6
            newValue.tank.item(1).stroke = SELECTED_TANK_OUTLINE_COLOR
            newValue.tank.item(1).strokeWidth = 6
            // Invalidate caching.
            // Needed for a special case where changing lock to a tank in the same viewport as precedent selection.
            newValue.tank.dirty = true
        },
        autoSpectate(newValue) {
            if (newValue) {
                this.lockCamera = true
            }
        },
        zoom() {
            this.doZoom()
        },
        lockCamera(newValue) {
            if (newValue === true) {
                this.centerPan()
                this.mainCanvas.hoverCursor = 'default'
            } else {
                this.mainCanvas.hoverCursor = 'move'
            }
        }
    },
    mounted() {
        this.mainCanvas = initFabricCreateMinimap()
        this.mainCanvas.setZoom(this.zoom)
        window.addEventListener('resize', this.resizeCanvas, false)
        this.resizeCanvas()
        this.minimap = createMinimap()

        this.initGrid()
        this.mainCanvas.on('mouse:wheel', (opt) => {
            const delta = opt.e.deltaY

            this.zoom += delta / 400
            this.doZoom(opt)
            opt.e.preventDefault()
            opt.e.stopPropagation()
        })
        this.mainCanvas.on('mouse:down', (opt) => {
            const evt = opt.e
            this.lockCamera = false
            this.autoSpectate = false
            this.mainCanvas.isDragging = true
            this.mainCanvas.selection = false
            this.mainCanvas.lastPosX = evt.clientX
            this.mainCanvas.lastPosY = evt.clientY
        })
        this.mainCanvas.on('mouse:move', (opt) => {
            if (this.mainCanvas.isDragging && !this.lockCamera) {
                const e = opt.e
                this.mainCanvas.relativePan(new fabric.Point(e.clientX - this.mainCanvas.lastPosX, e.clientY - this.mainCanvas.lastPosY))
                this.mainCanvas.requestRenderAll()
                this.mainCanvas.lastPosX = e.clientX
                this.mainCanvas.lastPosY = e.clientY
            }
        })
        this.mainCanvas.on('mouse:up', () => {
            this.mainCanvas.isDragging = false
        })

        const gameState = JSON.parse(generateSampleMap())

        gameState.players.forEach((player) => {
            const tank = createTank(player.fillColor)
            tank.left = player.position[0]
            tank.top = player.position[1]
            tank.angle = player.angle
            tank.fill = player.fillColor
            tank.id = player.id
            this.mainCanvas.add(tank)
            tank.bringToFront()
            player.tank = tank

            this.minimap.add(tank)

            const nameText = new fabric.Text(player.name, {
                top: tank.top + NAME_OFFSET,
                left: tank.left,
                fontSize: 35,
                fontFamily: 'Sans-Serif',
                originX: 'center',
                originY: 'center'
            })
            player.nameText = nameText
            this.mainCanvas.add(nameText)
            const healthBar = createHealthBar()
            player.healthBar = healthBar
            healthBar.item(1).width = player.health * HEALTHBAR_WIDTH
            healthBar.left = player.tank.left
            healthBar.top = player.tank.top + HEALTH_OFFSET
            this.mainCanvas.add(healthBar)
        })

        this.elements.players = gameState.players

        this.mainCanvas.renderAll()
        this.minimap.renderAll()

        window.requestAnimationFrame(this.doFrame)

    },
    methods: {
        doFrame() {
            const now = Date.now()
            if (this.autoSpectate && now - this.lastUpdateTimestamp > CANVAS_UPDATE_RATE) {
                this.focusedPlayer = this.orderedPlayers[0]
            }
            this.centerPan()
            this.hideIfUnzoomed()
            this.mainCanvas.renderAll()
            this.renderMinimap()
            window.requestAnimationFrame(this.doFrame)
        },
        drawAndRemoveProjectiles(updatedProjectiles) {
            const newProjectileIds = new Set()
            updatedProjectiles.forEach(projectile => {
                newProjectileIds.add(projectile.id)
                if (!this.elements.projectiles[projectile.id]) {
                    const newProjectile = createProjectile(this.elements.players.find(player => player.id === projectile.belongsTo))
                    this.elements.projectiles[projectile.id] = newProjectile
                    this.mainCanvas.add(newProjectile)
                    newProjectile.sendToBack()
                }
            })
            updatedProjectiles.forEach(projectile => {
                this.elements.projectiles[projectile.id].animate('left', projectile.position[0], {
                    onChange: null,
                    duration: ANIMATION_DURATION,
                    easing: linear
                })
                this.elements.projectiles[projectile.id].animate('top', projectile.position[1], {
                    onChange: null,
                    duration: ANIMATION_DURATION,
                    easing: linear
                })
            })
            const intersection = getDifference(this.elements.projectiles, newProjectileIds)
            intersection.forEach(id => {
                this.mainCanvas.remove(this.elements.projectiles[id])
                delete this.elements.projectiles[id]
            })
        },
        drawAndRemoveDebris(updatedDebris) {
            const newDebrisIds = new Set()
            updatedDebris.forEach(debris => {
                newDebrisIds.add(debris.id)
                if (!this.elements.debris[debris.id]) {
                    const method = Math.random() < 1/8 ? createDebris2 : createDebris1
                    const newDebris = method(Math.random() * 5000000000000)
                    newDebris.left = debris.position[0]
                    newDebris.top = debris.position[1]
                    this.elements.debris[debris.id] = newDebris
                    this.mainCanvas.add(newDebris)
                    newDebris.sendToBack()
                }
            })
            const difference = getDifference(this.elements.debris, newDebrisIds)
            difference.forEach(id => {
                this.mainCanvas.remove(this.elements.debris[id])
                delete this.elements.debris[id]
            })
        },
        /**
         * Called when a new game state arrives, updates the canvas and set intrapolation accordingly.
         * @param updatedGameState
         */
        animateCanvas(updatedGameState) {
            this.progress = updatedGameState.progress
            const updatedPlayers = updatedGameState.players
            updatedPlayers.forEach((updatedPlayer) => {
                const associatedPlayer = this.elements.players.find((player) => player.id === updatedPlayer.id)
                associatedPlayer.points = updatedPlayer.points
                associatedPlayer.tank.animate('left', updatedPlayer.position[0], {
                    onChange: null,
                    duration: ANIMATION_DURATION,
                    easing: linear
                })
                associatedPlayer.tank.animate('top', updatedPlayer.position[1], {
                    onChange: null,
                    duration: ANIMATION_DURATION,
                    easing: linear
                })
                associatedPlayer.tank.animate('angle', updatedPlayer.angle, {
                    onChange: null,
                    duration: ANIMATION_DURATION,
                    easing: linear
                })
                associatedPlayer.nameText.animate('left', updatedPlayer.position[0], {
                    onChange: null,
                    duration: ANIMATION_DURATION,
                    easing: linear
                })
                associatedPlayer.nameText.animate('top', updatedPlayer.position[1] + NAME_OFFSET, {
                    onChange: null,
                    duration: ANIMATION_DURATION,
                    easing: linear
                })
                associatedPlayer.healthBar.item(1).animate('width', updatedPlayer.health * HEALTHBAR_WIDTH, {
                    onChange: null,
                    duration: ANIMATION_DURATION,
                    easing: linear
                })
                associatedPlayer.healthBar.animate('left', updatedPlayer.position[0], {
                    onChange: null,
                    duration: ANIMATION_DURATION,
                    easing: linear
                })
                associatedPlayer.healthBar.animate('top', updatedPlayer.position[1] + HEALTH_OFFSET, {
                    onChange: null,
                    duration: ANIMATION_DURATION,
                    easing: linear
                })

            })
            this.drawAndRemoveProjectiles(updatedGameState.projectiles)
            this.drawAndRemoveDebris(updatedGameState.debris)
            this.lastUpdateTimestamp = Date.now()
        },
        hideIfUnzoomed() {
            if (this.zoom < 0.25) {
                this.elements.thinGrid.visible = false
                this.elements.players.forEach((player) => player.nameText.visible = false)
                this.elements.players.forEach((player) => player.healthBar.visible = false)
            }
            if (this.zoom >= 0.25) {
                this.elements.thinGrid.visible = true
                this.elements.players.forEach((player) => player.nameText.visible = true)
                this.elements.players.forEach((player) => player.healthBar.visible = true)
            }
        },
        doZoom(event=null) {
            if (this.zoom > MAX_ZOOM) this.zoom = MAX_ZOOM
            if (this.zoom < MIN_ZOOM) this.zoom = MIN_ZOOM
            if (this.lockCamera) {
                this.mainCanvas.setZoom(this.zoom)
            } else if (event !== null) {
                this.mainCanvas.zoomToPoint(new fabric.Point(event.e.offsetX, event.e.offsetY), this.zoom)
            }
            this.centerPan()
        },
        centerPan() {
            if (this.lockCamera && this.focusedPlayer) {
                this.mainCanvas.absolutePan(new fabric.Point(this.focusedPlayer.tank.left * this.zoom - (this.mainCanvas.getWidth() / 2), this.focusedPlayer.tank.top * this.zoom - (this.mainCanvas.getHeight() / 2)))
            }
        },
        initGrid() {
            const {thinGrid, thickGrid} = createGrid()

            this.elements.thinGrid = thinGrid
            this.elements.thickGrid = thickGrid

            this.mainCanvas.add(this.elements.thinGrid)
            this.mainCanvas.add(this.elements.thickGrid)
        },
        renderMinimap() {
            const canvasWidth = this.mainCanvas.getWidth() * (1/this.zoom)
            const canvasHeight = this.mainCanvas.getHeight() * (1/this.zoom)
            this.minimap.viewPort.width = canvasWidth
            this.minimap.viewPort.height = canvasHeight
            this.minimap.viewPort.left = (canvasWidth / 2) - this.mainCanvas.viewportTransform[4] * (1/this.zoom)
            this.minimap.viewPort.top = (canvasHeight / 2) - this.mainCanvas.viewportTransform[5] * (1/this.zoom)
            this.minimap.renderAll()
        },
        focusPlayer(player) {
            this.focusedPlayer = player
            this.autoSpectate = false
            this.lockCamera = true
        },
        resizeCanvas() {
            this.mainCanvas.setHeight(500)
            this.mainCanvas.setWidth(800)
            this.mainCanvas.renderAll()
        },
    }
})

networkInit()
