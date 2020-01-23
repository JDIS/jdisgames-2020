/**
 * Module to deal with elements that are drawn into canvases.
 */

import {GRID_COLOR, GRID_SIZE, GRID_STROKE, MAP_HEIGHT, MAP_WIDTH, MINIMAP_HEIGHT, MINIMAP_WIDTH} from "./constants.mjs"

/**
 * Canvas elements to be drawn on the main canvas
 */
export class DrawnElements {

    constructor(thickGrid, thinGrid, players, projectiles, debris) {
        this.thickGrid = thickGrid
        this.thinGrid = thinGrid
        this.players = players
        this.projectiles = projectiles
        this.debris = debris
    }
}

export function initFabricAndCreateMainCanvas() {
    fabric.perfLimitSizeTotal = 22500000
    fabric.maxCacheSideLimit = 11000
    fabric.Object.prototype.hasBorders = false
    fabric.Object.prototype.hasControls = false
    fabric.Object.prototype.originX = 'center'
    fabric.Object.prototype.originY = 'center'
    fabric.Group.prototype.selectable = false
    fabric.Group.prototype.originX = 'center'
    fabric.Group.prototype.originY = 'center'
    fabric.Group.prototype.hasBorders = false
    fabric.Group.prototype.hasControls = false

    return new fabric.Canvas('mon-canvas', {
        position: 'absolute',
        width: 500,
        height: 500,
        selection: false,
        renderOnAddRemove: false
    })
}

export function createMinimap() {
    const minimap = new fabric.StaticCanvas('minimap', {
        position: 'absolute',
        backgroundColor: 'white',
        width: MINIMAP_WIDTH,
        height: MINIMAP_HEIGHT,
        selection: false,
        renderOnAddRemove: false
    })
    minimap.setZoom(MINIMAP_WIDTH / MAP_HEIGHT)

    minimap.viewPort = new fabric.Rect({
        width: 0,
        height: 0,
        left: 0,
        top: 0,
        stroke: 'black',
        strokeWidth: 50,
        fill: null,
        objectCaching: false
    })
    minimap.add(minimap.viewPort)
    return minimap
}

export function createTank(fillColor) {
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

}

export function createProjectile(player) {

    const projectile = new fabric.Circle({
        radius: 15,
        fill: player.fillColor,
        stroke: 'black',
        strokeWidth: 3,
        left: player.tank.left,
        top: player.tank.top,
        originX: 'center',
        originY: 'center'
    })

    projectile.belongsTo = player

    return projectile

}

export function createDebris1(id) {
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
}

export function createDebris2(id) {
    const debris = new fabric.Triangle({
        width: 35,
        height: 30 ,
        angle: id % 360,
        stroke: 'green',
        strokeWidth: 3,
        fill: 'white'
    })
    debris.id = id
    return debris

}

export function createGrid() {
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

    return {
        thinGrid: new fabric.Group(thinGrid),
        thickGrid: new fabric.Group(thickGrid)
    }
}
