const GRID_SIZE = 250
const MAP_WIDTH = 5000
const MAP_HEIGHT = 5000
const MINIMAP_WIDTH = 100
const MAX_ZOOM = 4
const MIN_ZOOM = 0.05
const GRID_STROKE = 1
const GRID_COLOR = 'rgb(150,150,150)'
const NAME_OFFSET = -50
const HEALTH_OFFSET = 50
const HEALTHBAR_WIDTH = 50
const SELECTED_TANK_OUTLINE_COLOR = 'rgb(0,255,0)'
// in ms
const CANVAS_UPDATE_RATE = 1000 / 3
const ANIMATION_DURATION = 1000 / 3
const colors = ['#F60000', '#FF8C00', '#FFEE00', '#4DE94C', '#3783FF', '#4815AA', '#234E85', '#6E7C74', '#C7B763', '#D09D48', '#CA6220', '#C63501']
const linear = (t, b, c, d) => {
    return b + (t/d) * c
}
let frameNumber = 0
let lastUpdateTimestamp = Date.now()

const DEBRIS_TYPE = [1, 2]

function createHealthBar() {
    const background = new fabric.Rect({
        width: HEALTHBAR_WIDTH,
        height: 10,
        fill: 'rgb(200,200,200)',
        originX: 'left',
        originY: 'center'
    })

    const healthBar = new fabric.Rect({
        width: HEALTHBAR_WIDTH,
        height: 10,
        fill: 'rgb(20,255,20)',
        originX: 'left',
        originY: 'center'
    })

    return new fabric.Group([background, healthBar], {
        originX: 'center',
        originY: 'center',
    })
}
function generatePlayers() {
    const players = []
    for (let i = 0; i < 30; i++) {
        const tank = {
            name: `😎${i}`,
            id: i,
            position: [Math.random() * MAP_WIDTH, Math.random() * MAP_HEIGHT],
            angle: Math.random() * 360,
            health: Math.random(),
            fillColor: colors[i % colors.length],
            points: Math.random() * 1000
        };
        players.push(tank)
    }
    return players

}
function generateSampleMap() {

    const gameState = {
        progress: Math.random(),
        players: [],
        debris: []
    }

    gameState.players = generatePlayers();

    for (let i = 0; i < 700; i++) {
        const debris = {
            id: Math.round(Math.random() * 50000000000000).toString(),
            type: 1,
            position: [Math.random() * MAP_WIDTH, Math.random() * MAP_HEIGHT],
            health: Math.random(),
        };
        gameState.debris.push(debris)
    }

    for (let i = 0; i < 100; i++) {
        const debris = {
            id: i.toString(),
            type: 2,
            position: [Math.random() * MAP_WIDTH, Math.random() * MAP_HEIGHT],
            health: Math.random(),
        };
        gameState.debris.push(debris)
    }


    return JSON.stringify(gameState)
}

let app = new Vue({
    el: '#app',
    data: {
        zoom: 0.45,
        focusedPlayer: null,
        canvas: null,
        minimap: null,
        lockCamera: false,
        thickGrid: null,
        thinGrid: null,
        players: [],
        projectiles: {},
        debris: {},
        progress: 0,
        autoSpectate: false
    },
    computed: {
        zoomText() {
            return `${Math.round(this.zoom * 100, 2)}%`
        },
        orderedPlayers() {
            return this.players.sort((a, b) => a.points < b.points ? 1 : -1)
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
        autoSpectate(newValue, previousValue) {
            if (newValue) {
                this.lockCamera = true
            }
        },
        zoom(newValue, previousValue) {
            this.doZoom()
        },
        lockCamera(newValue, previousValue) {
            if (newValue === true) {
                this.centerPan()
                this.canvas.hoverCursor = 'default'
            } else {
                this.canvas.hoverCursor = 'move'
            }
        }
    },
    mounted() {
        fabric.perfLimitSizeTotal = 22500000;
        fabric.maxCacheSideLimit = 11000;
        this.canvas = new fabric.Canvas('mon-canvas', {
            position: 'absolute',
            width: 500,
            height: 500,
            selection: false,
            renderOnAddRemove: false
        })
        this.canvas.setZoom(this.zoom)
        window.addEventListener('resize', this.resizeCanvas, false);
        this.resizeCanvas();
        this.initMinimap()
        fabric.Object.prototype.hasBorders = false
        fabric.Object.prototype.hasControls = false
        fabric.Object.prototype.originX = 'center'
        fabric.Object.prototype.originY = 'center'
        fabric.Group.prototype.selectable = false
        fabric.Group.prototype.hasControls = false
        fabric.Group.prototype.hasBorders = false

        this.initGrid()
        this.canvas.on('mouse:wheel', (opt) => {
            const delta = opt.e.deltaY;

            this.zoom += delta / 400;
            this.doZoom(opt)
            opt.e.preventDefault();
            opt.e.stopPropagation();
        })
        this.canvas.on('mouse:down', (opt) => {
            const evt = opt.e;
            this.lockCamera = false
            this.autoSpectate = false
            this.canvas.isDragging = true
            this.canvas.selection = false
            this.canvas.lastPosX = evt.clientX
            this.canvas.lastPosY = evt.clientY
        })
        this.canvas.on('mouse:move', (opt) => {
            if (this.canvas.isDragging && !this.lockCamera) {
                const e = opt.e;
                this.canvas.relativePan(new fabric.Point(e.clientX - this.canvas.lastPosX, e.clientY - this.canvas.lastPosY));
                this.canvas.requestRenderAll();
                this.canvas.lastPosX = e.clientX;
                this.canvas.lastPosY = e.clientY;
            }
        })
        this.canvas.on('mouse:up', (opt) => {
            this.canvas.isDragging = false;
        })

        const gameState = JSON.parse(generateSampleMap())

        this.progress = gameState.progress

        gameState.debris.forEach((debris) => {
            const generator = debris.type === 1 ? this.createDebris1 : this.createDebris2
            const fabricObj = generator(debris.id)
            fabricObj.left = debris.position[0]
            fabricObj.top = debris.position[1]
            this.debris[debris.id] = fabricObj
            this.canvas.add(fabricObj)
        })

        gameState.players.forEach((player) => {
            const tank = this.createTank(player.fillColor, player.name)
            tank.left = player.position[0]
            tank.top = player.position[1]
            tank.angle = player.angle
            tank.fill = player.fillColor
            tank.id = player.id
            this.canvas.add(tank)
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
            this.canvas.add(nameText)
            const healthBar = createHealthBar()
            player.healthBar = healthBar
            healthBar.item(1).width = player.health * HEALTHBAR_WIDTH
            healthBar.left = player.tank.left
            healthBar.top = player.tank.top + HEALTH_OFFSET
            this.canvas.add(healthBar)
        })

        this.players = gameState.players

        this.canvas.renderAll()
        this.minimap.renderAll()

        window.requestAnimationFrame(this.doFrame)

    },
    methods: {
        doFrame() {
            console.log('frame')
            const now = Date.now()
            if (now - lastUpdateTimestamp > CANVAS_UPDATE_RATE) {
                this.animateCanvas();
                if (this.autoSpectate) {
                    this.focusedPlayer = this.orderedPlayers[0]
                }
            }
            this.centerPan()
            this.hideIfUnzoomed()
            this.canvas.renderAll()
            this.renderMinimap()
            frameNumber++
            window.requestAnimationFrame(this.doFrame)
        },
        drawAndRemoveProjectiles(updatedProjectiles) {
            const newProjectileIds = new Set()
            updatedProjectiles.forEach(projectile => {
                newProjectileIds.add(projectile.id)
                if (!this.projectiles[projectile.id]) {
                    const newProjectile = this.createProjectile(this.players.find(player => player.id === projectile.belongsTo));
                    this.projectiles[projectile.id] = newProjectile
                    this.canvas.add(newProjectile)
                    newProjectile.sendToBack()
                }
            })
            updatedProjectiles.forEach(projectile => {
                this.projectiles[projectile.id].animate('left', projectile.position[0], {
                    onChange: null,
                    duration: ANIMATION_DURATION,
                    easing: linear
                })
                this.projectiles[projectile.id].animate('top', projectile.position[1], {
                    onChange: null,
                    duration: ANIMATION_DURATION,
                    easing: linear
                })
            })
            const allProjectilesIds = new Set(Object.keys(this.projectiles))
            const intersection = new Set([...allProjectilesIds].filter(x => !newProjectileIds.has(x)))
            intersection.forEach(id => {
                this.canvas.remove(this.projectiles[id])
                delete this.projectiles[id]
            })
        },
        drawAndRemoveDebris(updatedDebris) {
            const newDebrisIds = new Set()
            updatedDebris.forEach(debris => {
                newDebrisIds.add(debris.id)
                if (!this.debris[debris.id]) {
                    const newDebris = this.createDebris1(Math.random() * 5000000000000);
                    newDebris.left = debris.position[0]
                    newDebris.top = debris.position[1]
                    this.debris[debris.id] = newDebris
                    this.canvas.add(newDebris)
                    newDebris.sendToBack()
                }
            })
            const allDebrisIds = new Set(Object.keys(this.debris))
            const difference = new Set([...allDebrisIds].filter(x => !newDebrisIds.has(x)))
            difference.forEach(id => {
                this.canvas.remove(this.debris[id])
                delete this.debris[id]
            })
        },
        animateCanvas() {
            const updatedGameState = JSON.parse(this.generateNextFrame(this.players, this.progress));
            this.progress = updatedGameState.progress
            const updatedPlayers = updatedGameState.players
            updatedPlayers.forEach((updatedPlayer) => {
                const associatedPlayer = this.players.find((player) => player.id === updatedPlayer.id)
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
            this.drawAndRemoveProjectiles(updatedGameState.projectiles);
            this.drawAndRemoveDebris(updatedGameState.debris)
            lastUpdateTimestamp = Date.now()
        },
        hideIfUnzoomed() {
            if (this.zoom < 0.25) {
                this.thinGrid.visible = false
                this.players.forEach((player) => player.nameText.visible = false)
                this.players.forEach((player) => player.healthBar.visible = false)
            }
            if (this.zoom >= 0.25) {
                this.thinGrid.visible = true
                this.players.forEach((player) => player.nameText.visible = true)
                this.players.forEach((player) => player.healthBar.visible = true)
            }
        },
        doZoom(event=null) {
            if (this.zoom > MAX_ZOOM) this.zoom = MAX_ZOOM;
            if (this.zoom < MIN_ZOOM) this.zoom = MIN_ZOOM;
            if (this.lockCamera) {
                this.canvas.setZoom(this.zoom);
            } else if (event !== null) {
                this.canvas.zoomToPoint(new fabric.Point(event.e.offsetX, event.e.offsetY), this.zoom)
            }
            this.centerPan()
        },
        centerPan() {
            if (this.lockCamera && this.focusedPlayer) {
                this.canvas.absolutePan(new fabric.Point(this.focusedPlayer.tank.left * this.zoom - (this.canvas.getWidth() / 2), this.focusedPlayer.tank.top * this.zoom - (this.canvas.getHeight() / 2)))
            }
        },
        initGrid() {
            const thinGrid = []
            const thickGrid = []
            for (let i = 0; i <= MAP_HEIGHT; i += GRID_SIZE) {
                if (i % 1000 === 0) {
                    thickGrid.push(new fabric.Line([0, i, MAP_WIDTH, i], {
                        stroke: GRID_COLOR,
                        strokeWidth: i === 0 || i === MAP_HEIGHT ? GRID_STROKE * 20 : GRID_STROKE * 5,
                    }))
                } else {
                    thinGrid.push(new fabric.Line([0, i, MAP_WIDTH, i], {
                        stroke: GRID_COLOR,
                        strokeWidth: GRID_STROKE,
                    }))
                }
            }
            for (let i = 0; i <= MAP_WIDTH; i += GRID_SIZE) {
                if (i % 1000 === 0) {
                    thickGrid.push(new fabric.Line([i, 0, i, MAP_HEIGHT], {
                        stroke: GRID_COLOR,
                        strokeWidth: i === 0 || i === MAP_WIDTH ? GRID_STROKE * 20 : GRID_STROKE * 5,
                        originX: 'center',
                        originY: 'center'
                    }))
                } else {
                    thinGrid.push(new fabric.Line([i, 0, i, MAP_HEIGHT], {
                        stroke: GRID_COLOR,
                        strokeWidth: GRID_STROKE,
                        originX: 'center',
                        originY: 'center'
                    }))
                }
            }

            this.thickGrid = new fabric.Group(thickGrid)
            this.thinGrid = new fabric.Group(thinGrid)

            this.canvas.add(this.thickGrid)
            this.canvas.add(this.thinGrid)
        },
        initMinimap() {
            this.minimap = new fabric.StaticCanvas('minimap', {
                position: 'absolute',
                backgroundColor: 'white',
                width: MINIMAP_WIDTH,
                height: MINIMAP_WIDTH,
                selection: false,
                renderOnAddRemove: false
            })
            this.minimap.setZoom(MINIMAP_WIDTH / MAP_HEIGHT)

            this.minimap.viewPort = new fabric.Rect({
                width: 0,
                height: 0,
                left: 0,
                top: 0,
                stroke: 'black',
                strokeWidth: 50,
                fill: null,
                objectCaching: false
            })
            this.minimap.add(this.minimap.viewPort)
        },
        renderMinimap() {
            const canvasWidth = this.canvas.getWidth() * (1/this.zoom)
            const canvasHeight = this.canvas.getHeight() * (1/this.zoom)
            this.minimap.viewPort.width = canvasWidth
            this.minimap.viewPort.height = canvasHeight
            this.minimap.viewPort.left = (canvasWidth / 2) - this.canvas.viewportTransform[4] * (1/this.zoom)
            this.minimap.viewPort.top = (canvasHeight / 2) - this.canvas.viewportTransform[5] * (1/this.zoom)
            this.minimap.renderAll()
        },
        focusPlayer(player) {
            this.focusedPlayer = player
            this.autoSpectate = false
            this.lockCamera = true
        },
        resizeCanvas() {
            this.canvas.setHeight(500);
            this.canvas.setWidth(800);
            this.canvas.renderAll()
        },
        createTank(fillColor, name) {

            const tankCircle = new fabric.Circle({
                radius: 25,
                fill: fillColor,
                stroke: 'black',
                strokeWidth: 3,
                originX: 'center',
                originY: 'center',
                objectCaching: false

            })
            const tankRect = new fabric.Rect({
                width:27,
                height: 15,
                fill: 'black',
                top:-27,
                centeredRotation: false,
                originX: 'center',
                originY: 'center',
                objectCaching: false
            })
            const tank = new fabric.Group([tankCircle], {
                originX: 'center',
                originY: 'center',
                objectCaching: false // Needed since the players are also rendered on the minimap.
            })
            tank.add(tankRect)

            tankRect.sendToBack()
            return tank

        },
        createProjectile(player) {

            const projectile = new fabric.Circle({
                radius: 15,
                fill: player.fillColor,
                stroke: 'black',
                strokeWidth: 3,
                left: player.position[0],
                top: player.position[1],
                originX: 'center',
                originY: 'center'
            })

            projectile.belongsTo = player

            return projectile

        },
        generateNextFrame(players, progress) {
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
                newPlayer.position[0] = newPlayer.position[0] + (Math.floor(Math.random() * 40) - 10)
                newPlayer.position[1] = newPlayer.position[1] + (Math.floor(Math.random() * 40) - 10)

                if (frameNumber % 3 === 0) {
                    newProjectiles.push({
                        id: Math.round(Math.random() * 500000000000).toString(),
                        position: [newPlayer.position[0] + 100, newPlayer.position[1] + 60],
                        fillColor: newPlayer.fillColor,
                        belongsTo: newPlayer.id,

                    })
                }

                newPlayers.push(newPlayer)
            }

            Object.keys(this.projectiles).map((id) => {
                if (Math.random() < 0.7) {
                    newProjectiles.push({
                        belongsTo: this.projectiles[id].belongsTo,
                        fillColor: this.projectiles[id].fill,
                        position: [this.projectiles[id].left + 100, this.projectiles[id].top + 60],
                        id: id
                    })
                }
            })

            const debris = []
            Object.keys(this.debris).map((id) => {
                if (Math.random() < 0.99) {
                    debris.push({
                        id: id,
                        type: this.debris[id].type,
                        position: [this.debris[id].left, this.debris[id].top],
                        health: this.debris[id].health,
                    })
                }
            })

            for (let i = 0; i < 800; i++) {
                if (Math.random() >= 0.99) {
                    debris.push({
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
                debris: debris
            })
        },
        createDebris1(id) {
            const debris = new fabric.Rect({
                width: 25,
                height: 25,
                angle: id % 360,
                stroke: 'black',
                strokeWidth: 3,
                fill: 'grey'
            })
            debris.id = id
            return debris
        },
        createDebris2(id) {
            const debris = new fabric.Triangle({
                width: 35,
                height: 30 ,
                angle: id % 360,
                stroke: 'green',
                strokeWidth: 3,
                fill: 'white'
            });
            debris.id = id
            return debris

        }
    }
})
