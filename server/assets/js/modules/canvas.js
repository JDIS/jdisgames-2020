/**
 * Module to deal with elements that are drawn into canvases.
 */

import {GRID_COLOR, GRID_SIZE, GRID_STROKE, MAP_HEIGHT, MAP_WIDTH, MINIMAP_HEIGHT, MINIMAP_WIDTH} from "./constants.js"

/**
 * Canvas elements to be drawn on the main canvas
 */
export class DrawnElements {

    constructor(thickGrid, thinGrid, tanks, projectiles, debris) {
        this.thickGrid = thickGrid
        this.thinGrid = thinGrid
        this.tanks = tanks
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

    const canvas = new fabric.Canvas('mon-canvas', {
        position: 'absolute',
        width: 500,
        height: 500,
        selection: false,
        renderOnAddRemove: false
    });

    canvas.setBackgroundImage('/images/jdis.svg', null, {
        opacity: 0.2,
        angle: 0,
        top: MAP_HEIGHT / 2,
        left: MAP_WIDTH / 2,
        width: MAP_WIDTH / 1.05,
        height: MAP_HEIGHT / 1.05,
        originX: 'center',
        originY: 'center'
    })

    return canvas
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
        objectCaching: true
    })
    minimap.add(minimap.viewPort)
    return minimap
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
