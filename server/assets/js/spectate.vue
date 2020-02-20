<template>
    <div>
        <div class="container">
            <div class="row">
                <div :class="{nine: !fullScreen, twelve: fullScreen}" class="columns">
                    <div class="flex">
                        <label style="display: inline-block"> Auto-spectate <input style="margin: 0" type="checkbox" v-model="autoSpectate" /></label>
                        <label style="display: inline-block"> Full screen <input style="margin: 0" type="checkbox" v-model="fullScreen" /></label>
                        <progress id="progress" :value="progress * 100" max="100"></progress>
                    </div>
                    <div id="invisible"></div>
                    <div id="canvas-container">
                        <canvas id="mon-canvas" style="border: 1px solid black;width:100%;margin: auto;position:absolute;top:0;"></canvas>
                        <canvas id="minimap" style="border: 1px solid green;position:absolute;top:5px;left:5px"></canvas>
                    </div>
                </div>
                <div class="three columns" v-show="!fullScreen">
                    <div class="flex">
                        <strong class="rank">#</strong>
                        <div class="player-name">Team</div>
                        <strong class="points">Points</strong>
                    </div>
                    <div v-for="(tank, index) in orderedTanks" class="flex scoreboard" @click="focusPlayer(tank)">
                        <strong class="rank">{{index + 1}}</strong>
                        <input class="player-name" type="button" :value="`${tank.name}`"
                               :style="{backgroundColor: tank.fillColor}" />
                        <strong class="points">{{ Math.round(tank.points) }}</strong>
                    </div>
                    <hr>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
    import Vue from "vue"
    import {createSmallDebris, createMediumDebris, createLargeDebris, createGrid, createMinimap, createProjectile, createTank, DrawnElements, initFabricAndCreateMainCanvas} from "./modules/canvas.js"
    import {ANIMATION_DURATION, CANVAS_UPDATE_RATE, FADE_DURATION, HEALTH_OFFSET, HEALTHBAR_WIDTH, linear, MAX_ZOOM, MIN_ZOOM, NAME_OFFSET, SELECTED_TANK_OUTLINE_COLOR} from "./modules/constants.js"
    import {createHealthBar} from "./modules/mock.js"
    import {getDifference} from "./modules/utils.js"
    import {COLORS} from "./modules/constants";

    export default Vue.extend({
        name: 'Spectate',
        data() {
            return {
                zoom: 0.45,
                fullScreen: false,
                focusedPlayer: null,
                mainCanvas: null,
                minimap: null,
                lockCamera: false,
                elements: new DrawnElements(null, null, [], {}, {}),
                progress: 0,
                autoSpectate: false,
                lastUpdateTimestamp: Date.now()
            }
        },
        computed: {
            /**
             * @returns List of tanks ordered by their score in the current game.
             */
            orderedTanks() {
                return Object.values(this.elements.tanks).sort((a, b) => a.points < b.points ? 1 : -1)
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
            },
            fullScreen() {
                window.setTimeout(this.resizeCanvas, 100)
            }
        },
        mounted() {
            this.mainCanvas = initFabricAndCreateMainCanvas()
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
        },
        methods: {
            startRendering(gameState) {
                Object.keys(gameState.tanks).forEach((id) => {
                    let color = COLORS[id % COLORS.length];
                    const tank = createTank(color)
                    const player = gameState.tanks[id]
                    player.fillColor = color
                    tank.left = player.position[0]
                    tank.top = player.position[1]
                    tank.angle = player.angle
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

                this.elements.tanks = gameState.tanks

                this.autoSpectate = true
                this.mainCanvas.renderAll()
                this.minimap.renderAll()

                window.requestAnimationFrame(this.doFrame)
            },
            doFrame() {
                const now = Date.now()
                if (this.autoSpectate && now - this.lastUpdateTimestamp > CANVAS_UPDATE_RATE) {
                    this.focusedPlayer = this.orderedTanks[0]
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
                        const newProjectile = createProjectile(Object.values(this.elements.tanks).find(player => player.id === projectile.belongsTo))
                        this.elements.projectiles[projectile.id] = newProjectile
                        this.mainCanvas.add(newProjectile)
                        newProjectile.sendBackwards(this.elements.tanks[0])
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
                const difference = getDifference(this.elements.projectiles, newProjectileIds)
                difference.forEach(id => {
                    const element = this.elements.projectiles[id]
                    delete this.elements.projectiles[id]
                    element.animate('opacity', 0, {
                        easing: linear,
                        duration: FADE_DURATION,
                        onComplete: () => {this.mainCanvas.remove(element)},
                        onChange: null
                    })
                })
            },
            drawAndRemoveDebris(updatedDebris) {
                const newDebrisIds = new Set()
                updatedDebris.forEach(debris => {
                    newDebrisIds.add(debris.id)
                    if (!this.elements.debris[debris.id]) {
                        const method = this.debrisCreationMethod(debris.size)
                        const newDebris = method(debris.id)
                        newDebris.left = debris.position[0]
                        newDebris.top = debris.position[1]
                        this.elements.debris[debris.id] = newDebris
                        this.mainCanvas.add(newDebris)
                        newDebris.sendBackwards(this.elements.tanks[0])
                    }
                })
                const difference = getDifference(this.elements.debris, newDebrisIds)
                difference.forEach(id => {
                    const debris = this.elements.debris[id]
                    delete this.elements.debris[id]
                    debris.animate('opacity', 0, {
                        easing: linear,
                        duration: FADE_DURATION,
                        onComplete: () => {this.mainCanvas.remove(debris)},
                        onChange: null
                    })
                })
            },
            debrisCreationMethod(size) {
                switch(size) {
                    case "small":
                        return createSmallDebris;
                    case "medium":
                        return createMediumDebris;
                    case "large":
                        return createLargeDebris;
                }
            },
            /**
             * Called when a new game state arrives, updates the canvas and set intrapolation accordingly.
             * @param updatedGameState
             */
            animateCanvas(updatedGameState) {
                this.progress = updatedGameState.ticks / updatedGameState.max_ticks
                const updatedTanks = updatedGameState.tanks
                Object.keys(updatedTanks).forEach((id) => {
                    const updatedTank = updatedTanks[id]
                    const associatedPlayer = this.elements.tanks[id]
                    associatedPlayer.points = updatedTank.points
                    associatedPlayer.tank.animate('left', updatedTank.position[0], {
                        onChange: null,
                        duration: ANIMATION_DURATION,
                        easing: linear
                    })
                    associatedPlayer.tank.animate('top', updatedTank.position[1], {
                        onChange: null,
                        duration: ANIMATION_DURATION,
                        easing: linear
                    })
                    // associatedPlayer.tank.animate('angle', updatedTank.angle, {
                    //     onChange: null,
                    //     duration: ANIMATION_DURATION,
                    //     easing: linear
                    // })
                    associatedPlayer.nameText.animate('left', updatedTank.position[0], {
                        onChange: null,
                        duration: ANIMATION_DURATION,
                        easing: linear
                    })
                    associatedPlayer.nameText.animate('top', updatedTank.position[1] + NAME_OFFSET, {
                        onChange: null,
                        duration: ANIMATION_DURATION,
                        easing: linear
                    })
                    associatedPlayer.healthBar.item(1).animate('width', updatedTank.health * HEALTHBAR_WIDTH, {
                        onChange: null,
                        duration: ANIMATION_DURATION,
                        easing: linear
                    })
                    associatedPlayer.healthBar.animate('left', updatedTank.position[0], {
                        onChange: null,
                        duration: ANIMATION_DURATION,
                        easing: linear
                    })
                    associatedPlayer.healthBar.animate('top', updatedTank.position[1] + HEALTH_OFFSET, {
                        onChange: null,
                        duration: ANIMATION_DURATION,
                        easing: linear
                    })

                })
                // this.drawAndRemoveProjectiles(updatedGameState.projectiles)
                this.drawAndRemoveDebris(updatedGameState.debris)
                this.lastUpdateTimestamp = Date.now()
            },
            hideIfUnzoomed() {
                if (this.zoom < 0.25) {
                    this.elements.thinGrid.visible = false
                    Object.values(this.elements.tanks).forEach((player) => player.nameText.visible = false)
                    Object.values(this.elements.tanks).forEach((player) => player.healthBar.visible = false)
                }
                if (this.zoom >= 0.25) {
                    this.elements.thinGrid.visible = true
                    Object.values(this.elements.tanks).forEach((player) => player.nameText.visible = true)
                    Object.values(this.elements.tanks).forEach((player) => player.healthBar.visible = true)
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

                thickGrid.sendToBack()
                thinGrid.sendToBack()
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
                this.mainCanvas.setHeight(window.innerHeight * 0.95)
                this.mainCanvas.setWidth(document.querySelector('#invisible').offsetWidth)
                this.mainCanvas.renderAll()
            },
        }
    })
</script>

