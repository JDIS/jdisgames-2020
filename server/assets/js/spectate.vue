<template>
    <div>
        <div class="container">
            <div class="flex">
                <label style="display: inline-block"> Auto-spectate <input style="margin: 0" type="checkbox" v-model="autoSpectate" /></label>
                <label style="display: inline-block"> Full screen <input style="margin: 0" type="checkbox" v-model="fullScreen" /></label>
                <label style="display: inline-block"> Performance mode <input style="margin: 0" type="checkbox" v-model="performanceMode" /></label>
                <progress id="progress" :value="progress * 100" max="100"></progress>
                <span title="Nombre de débris sur la carte">🔺 {{ debrisCount }} 🔻</span>
            </div>
            <div class="row">
                <div :class="{nine: !fullScreen, twelve: fullScreen}" class="columns">
                    <div id="invisible"></div>
                    <div id="canvas-container">
                        <canvas id="mon-canvas" style="border: 1px solid black;width:100%;margin: auto;position:absolute;top:0;"></canvas>
                        <canvas id="minimap" style="border: 1px solid green;position:absolute;top:5px;left:5px"></canvas>
                    </div>
                </div>
                <div class="three columns" style="position: absolute; right: -1em; background-color: rgba(255,255,255,0.7);padding: 0.5em;margin:0;">
                    <div v-if="focusedPlayer">
                        <h3 style="margin-bottom: 0;text-align: center">{{focusedPlayer.name.text}}</h3>
                        <div style="width:100%; height: 15px" :style="{'background': `${focusedPlayer.color}`}"></div>
                        <table>
                            <tr>
                                <td>❤️ HP</td>
                                <td><strong>{{Math.round(focusedPlayer.current_hp)}}</strong>/{{focusedPlayer.max_hp}} (LVL {{ focusedPlayer.upgrade_levels.max_hp }})</td>
                            </tr>
                            <tr>
                                <td>💣 Projectile damage</td>
                                <td><strong>{{focusedPlayer.projectile_damage}}</strong> (LVL {{ focusedPlayer.upgrade_levels.projectile_damage }})</td>
                            </tr>
                            <tr>
                                <td title="Cooldown between each projectile launch">🕒 Fire rate <span style="font-size: 70%">(?)</span></td>
                                <td><strong>{{focusedPlayer.fire_rate}}</strong> (LVL {{ focusedPlayer.upgrade_levels.fire_rate }})</td>
                            </tr>
                            <tr>
                                <td>🐇 Speed </td>
                                <td><strong>{{focusedPlayer.speed}}</strong> (LVL {{ focusedPlayer.upgrade_levels.speed }})</td>
                            </tr>
                            <tr>
                                <td title="Damage another entity takes upon colliding with it.">👊 Body damage </td>
                                <td><strong>{{focusedPlayer.body_damage}}</strong> (LVL {{ focusedPlayer.upgrade_levels.body_damage }})</td>
                            </tr>
                            <tr>
                                <td title="HP regenerated every tick.">💞 HP regen </td>
                                <td><strong>{{focusedPlayer.hp_regen}}</strong> (LVL {{ focusedPlayer.upgrade_levels.hp_regen }})</td>
                            </tr>
                            <tr>
                              <td title="Projectile time to live.">🚀 Projectile time to live</td>
                              <td><strong>{{ focusedPlayer.projectile_time_to_live }}</strong> (LVL {{ focusedPlayer.upgrade_levels.projectile_time_to_live }})</td>
                            </tr>
                            <tr>
                                <td>🆙 Upgrade tokens available </td>
                                <td><strong>{{focusedPlayer.upgrade_tokens}}</strong></td>
                            </tr>

                        </table>
                    </div>
                    <div style="max-height: 55.5vh; overflow-y:scroll">
                        <div class="flex">
                            <strong class="rank">#</strong>
                            <div class="player-name">Team</div>
                            <strong class="points">Points</strong>
                        </div>
                        <div v-for="(tank, index) in orderedTanks" class="flex scoreboard" @click="focusPlayer(tank)">
                            <strong class="rank">{{index + 1}}</strong>
                            <input class="player-name" type="button" :value="`${tank.name.text}`"
                                   :style="{backgroundColor: tank.color}" />
                            <strong class="points">{{ Math.round(tank.score) }}</strong>
                        </div>
                        <hr>
                    </div>
                </div>
            </div>
        </div>
        <audio id="tankHitAudio" src="/audio/tank_hit.wav" style="display: none" controls="none" preload="auto"></audio>
    </div>
</template>

<script>
    import { fabric } from 'fabric';
    import {createGrid, createMinimap, DrawnElements, initFabricAndCreateMainCanvas} from "./modules/canvas.js"
    import {CANVAS_UPDATE_RATE, MAX_ZOOM, MIN_ZOOM} from "./modules/constants.js"
    import {getDifference} from "./modules/utils.js"
    import {COLORS} from "./modules/constants";
    import {Tank} from "./classes/Tank";
    import {Debris} from "./classes/Debris";
    import {Projectile} from "./classes/Projectile";

    export default {
        name: 'Spectate',
        data() {
            return {
                zoom: 0.45,
                fullScreen: true,
                focusedPlayer: null,
                mainCanvas: null,
                minimap: null,
                lockCamera: false,
                elements: new DrawnElements(null, null, {}, {}, {}),
                progress: 0,
                debrisCount: 0,
                autoSpectate: false,
                lastUpdateTimestamp: Date.now(),
                tankHitSound: null,
                performanceMode: false,
                i: 0
            }
        },
        then: Date.now(),
        computed: {
            /**
             * @returns List of tanks ordered by their score in the current game.
             */
            orderedTanks() {
                return Object.values(this.elements.tanks).sort((a, b) => a.score < b.score ? 1 : -1)
            }
        },
        watch: {
            focusedPlayer(newValue, previousValue) {
                if (previousValue) {
                    previousValue.unselect()
                }
                if (newValue) {
                    newValue.select()
                }
            },
            autoSpectate(newValue) {
                if (newValue) {
                    this.lockCamera = true
                }
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
            this.tankHitSound = document.querySelector('#tankHitAudio')

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
                    const tank = new Tank(gameState.tanks[id])
                    this.mainCanvas.add(tank.toCanvas)
                    this.minimap.add(tank.body)
                    tank.toCanvas.bringToFront()
                    this.elements.tanks[id] = tank
                })

                this.autoSpectate = true
                this.mainCanvas.renderAll()
                this.minimap.renderAll()

                window.requestAnimationFrame(this.doFrame)
            },
            /**
             * Capped at 30 fps
             **/
            doFrame() {
                window.requestAnimationFrame(this.doFrame)

                const now = Date.now()
                this.$options.then = now
                if (this.autoSpectate && now - this.lastUpdateTimestamp > CANVAS_UPDATE_RATE) {
                    this.focusedPlayer = this.orderedTanks[0]
                }
                this.i++
                if (!this.performanceMode) {
                    this.centerPan()
                } else if(this.i % 60 === 0) {
                    this.centerPan()
                }
                this.hideIfUnzoomed()
                this.mainCanvas.renderAll()
                if(this.performanceMode && this.i % 60 === 0) {
                    this.renderMinimap()
                } else if(this.i % 2 === 0) {
                    this.renderMinimap()
                }
            },
            drawAndRemoveProjectiles(updatedProjectiles) {
                const newProjectileIds = new Set()
                updatedProjectiles.forEach(projectile => {
                    newProjectileIds.add(projectile.id)
                    if (!this.elements.projectiles[projectile.id]) {
                        const newProjectile = new Projectile(this.elements.tanks[projectile.owner_id], projectile)
                        this.elements.projectiles[projectile.id] = newProjectile
                        const tank_index = this.mainCanvas.getObjects().indexOf(this.elements.tanks[projectile.owner_id].toCanvas)
                        this.mainCanvas.insertAt(newProjectile.fabricObj, tank_index, false)
                    }
                })
                updatedProjectiles.forEach(projectile => {
                    this.elements.projectiles[projectile.id].update(projectile)
                })
                const difference = getDifference(this.elements.projectiles, newProjectileIds)
                difference.forEach(id => {
                    const projectile = this.elements.projectiles[id]
                    delete this.elements.projectiles[id]
                    projectile.die(() => this.mainCanvas.remove(projectile))
                })
            },
            drawAndRemoveDebris(updatedDebris) {
                const newDebrisIds = new Set()
                this.debrisCount = updatedDebris.length
                updatedDebris.forEach(debris => {
                    newDebrisIds.add(debris.id)
                    if (!this.elements.debris[debris.id]) {
                        const newDebris = new Debris(debris)
                        this.elements.debris[debris.id] = newDebris
                        this.mainCanvas.add(newDebris.fabricObj)
                        this.mainCanvas.sendBackwards(newDebris.fabricObj)
                    } else {
                        this.elements.debris[debris.id].update(debris)
                    }
                })
                const difference = getDifference(this.elements.debris, newDebrisIds)
                difference.forEach(id => {
                    const debris = this.elements.debris[id]
                    delete this.elements.debris[id]
                    debris.die(() => this.mainCanvas.remove(debris))
                })
            },

            /**
             * Called when a new game state arrives, updates the canvas and set intrapolation accordingly.
             * @param updatedGameState
             */
            animateCanvas(updatedGameState) {
                this.progress = updatedGameState.clock.current_tick / updatedGameState.clock.max_tick
                const updatedTanks = updatedGameState.tanks
                Object.keys(updatedTanks).forEach((id) => {
                    const updatedTank = updatedTanks[id]
                    const tank = this.elements.tanks[id]
                    tank.update(updatedTank, this.playTankHitSound)
                })
                if(this.focusedPlayer) {
                    this.focusedPlayer.updateLines(this.mainCanvas)
                }
                this.drawAndRemoveProjectiles(updatedGameState.projectiles)
                this.drawAndRemoveDebris(updatedGameState.debris)
                this.lastUpdateTimestamp = Date.now()
            },
            hideIfUnzoomed() {
                const isVisible = this.zoom >= 0.25;
                this.elements.thinGrid.visible = isVisible

                Object.values(this.elements.tanks).forEach((tank) => tank.setHUDVisible(isVisible))
            },
            doZoom(event=null) {
                if (this.zoom > MAX_ZOOM) this.zoom = MAX_ZOOM
                if (this.zoom < MIN_ZOOM) this.zoom = MIN_ZOOM
                if (this.lockCamera) {
                    this.mainCanvas.setZoom(this.zoom)
                } else if (event !== null) {
                    this.mainCanvas.zoomToPoint(new fabric.Point(event.e.offsetX, event.e.offsetY), this.zoom)
                }
                //this.centerPan()
            },
            centerPan() {
                if (this.lockCamera && this.focusedPlayer) {
                    this.mainCanvas.absolutePan(
                        new fabric.Point(
                            this.focusedPlayer.left() * this.zoom - (this.mainCanvas.getWidth() / 2),
                            this.focusedPlayer.top() * this.zoom - (this.mainCanvas.getHeight() / 2))
                    )
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

            getColor(focusedPlayer) {
                return COLORS[focusedPlayer.id % COLORS.length];
            },

            /**
             * Play a hit sound if the hit tank is the focused tank.
             */
            playTankHitSound(tank) {
                if (tank === this.focusedPlayer) {
                    const clone = this.tankHitSound.cloneNode()
                    clone.play()
                }
            }
        }
    }
</script>

