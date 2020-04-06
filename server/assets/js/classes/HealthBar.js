import {ANIMATION_DURATION, HEALTH_OFFSET, HEALTHBAR_WIDTH, linear} from "../modules/constants";

const FACTOR = 0.8;

export class HealthBar {

    constructor(serverTank) {
        this.healthBarWidth = serverTank.max_hp * FACTOR
        this.background = this.createBackground()
        this.healthBar = this.createHealthBar()
        this.toCanvas = this.createFabricObj(serverTank);
    }

    update(newServerTank) {
        this.healthBarWidth = newServerTank.max_hp * FACTOR
        this.toCanvas.width = this.healthBarWidth
        this.background.width = this.healthBarWidth

        this.healthBar.animate('width', (newServerTank.current_hp / newServerTank.max_hp) * this.healthBarWidth, {
            onChange: null,
            duration: ANIMATION_DURATION,
            easing: linear
        })
    }

    createBackground() {
        return new fabric.Rect({
            width: HEALTHBAR_WIDTH,
            height: 10,
            fill: 'rgb(200,200,200)',
            originX: 'center',
            originY: 'center'
        })
    }

    createFabricObj(serverTank) {
        return new fabric.Group([this.background, this.healthBar], {
            originX: 'center',
            originY: 'center',
            left: serverTank.position[0],
            top: serverTank.position[1] + HEALTH_OFFSET
        });
    }

    createHealthBar() {
        return new fabric.Rect({
            width: this.healthBarWidth,
            height: 10,
            fill: 'rgb(20,255,20)',
            originX: 'center',
            originY: 'center'
        })
    }
}