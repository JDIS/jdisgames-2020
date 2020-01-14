const GRID_SIZE = 250
const MAP_WIDTH = 5000
const MAP_HEIGHT = 5000
const MAX_ZOOM = 4;
const MIN_ZOOM = 0.05;
const GRID_STROKE = 1
const GRID_COLOR = 'rgb(150,150,150)'
const NAME_OFFSET = -50
const HEALTH_OFFSET = 50
const HEALTHBAR_WIDTH = 50
const SELECTED_TANK_OUTLINE_COLOR = 'rgb(0,255,0)'
// in ms
const CANVAS_UPDATE_RATE = 1000 / 1
const ANIMATION_DURATION = 1000 / 1
const colors = ['red', 'blue', 'yellow', 'cyan', 'purple', 'orange']
const linear = (t, b, c, d) => {
    return b + (t/d) * c
}
let frameNumber = 0
let lastUpdateTimestamp = Date.now()

const DEBRIS_TYPE = [1, 2]
function createDebris1(id) {
    return new fabric.Rect({
        width: 25,
        height: 25,
        angle: id % 360,
        stroke: 'black',
        strokeWidth: 3,
        fill: 'grey'
    })

}
function createDebris2(id) {
    return new fabric.Triangle({
        width: 35,
        height: 30 ,
        angle: id % 360,
        stroke: 'green',
        strokeWidth: 3,
        fill: 'white'
    })

}
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
            id: i,
            type: 1,
            position: [Math.random() * MAP_WIDTH, Math.random() * MAP_HEIGHT],
            health: Math.random(),
        };
        gameState.debris.push(debris)
    }

    for (let i = 0; i < 100; i++) {
        const debris = {
            id: i,
            type: 2,
            position: [Math.random() * MAP_WIDTH, Math.random() * MAP_HEIGHT],
            health: Math.random(),
        };
        gameState.debris.push(debris)
    }


    return JSON.stringify(gameState)
}
function generateNextFrame(players, progress) {
    newPlayers = []
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

        newPlayers.push(newPlayer)
    }

    return JSON.stringify({
        progress: (progress + 0.003) % 1,
        players: newPlayers
    })
}

let app = new Vue({
    el: '#app',
    data: {
        zoom: 0.45,
        focusedPlayer: null,
        canvas: null,
        lockCamera: false,
        thickGrid: null,
        thinGrid: null,
        players: [],
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
            width: 500,
            height: 500,
            selection: false,
            renderOnAddRemove: false
        })
        this.canvas.setZoom(this.zoom)
        window.addEventListener('resize', this.resizeCanvas, false);
        this.resizeCanvas();
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
            const generator = debris.type === 1 ? createDebris1 : createDebris2
            const fabricObj = generator(debris.id)
            fabricObj.left = debris.position[0]
            fabricObj.top = debris.position[1]
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
            frameNumber++
            window.requestAnimationFrame(this.doFrame)
        },
        animateCanvas() {
            const updatedGameState = JSON.parse(generateNextFrame(this.players, this.progress));
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
            lastUpdateTimestamp = Date.now()
        })
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
        focusPlayer(player) {
            this.focusedPlayer = player
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
                originY: 'center'
            })
            const tankRect = new fabric.Rect({
                width:27,
                height: 15,
                fill: 'black',
                top:-27,
                centeredRotation: false,
                originX: 'center',
                originY: 'center'
            })
            const tank = new fabric.Group([tankCircle], {
                originX: 'center',
                originY: 'center',
            })
            tank.add(tankRect)

            tankRect.sendToBack()
            return tank

        },
        createProjectile(belongsTo) {

            const projectile = new fabric.Circle({
                radius: 15,
                fill: belongsTo.fill,
                stroke: 'black',
                strokeWidth: 3,
                originX: 'center',
                originY: 'center'
            })

            return projectile

        }
    }
})
