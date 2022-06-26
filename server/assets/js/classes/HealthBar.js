import { fabric } from 'fabric';
import {ANIMATION_DURATION, HEALTH_OFFSET, linear, GAME_RATIO} from "../modules/constants";

const FACTOR = 0.8;

export class HealthBar {

    constructor(serverTank) {
        this.current_health = serverTank.current_hp
        this.max_health = serverTank.max_hp
        this.background = this.createBackground()
        this.healthBar = this.createHealthBar()
        this.toCanvas = this.createFabricObj(serverTank);
    }

    update(newServerTank) {
        if (newServerTank.current_hp !== this.current_health || this.max_health !== newServerTank.max_hp) {
            const newHealthBarWidth = this.healthBarWidth();
            this.current_health = newServerTank.current_hp
            this.max_health = newServerTank.max_hp
            this.toCanvas.width = newHealthBarWidth
            this.background.width = newHealthBarWidth
            this.healthBar.animate('width', (newServerTank.current_hp / newServerTank.max_hp) * newHealthBarWidth, {
                onChange: null,
                duration: ANIMATION_DURATION,
                easing: linear
            })
            this.healthBar.fill = this.getColor()
        }
    }

    getColor() {
        const ratio = this.current_health / this.max_health
        let g = Math.round(ratio * 255)
        let r = Math.round(255 - g)
        if (r < g) {
            r *= (1 + (r / 255))
        } else {
            g *= (1 + (g / 255))
        }
        return `rgb(${r},${g},20)`
    }

    createBackground() {
        return new fabric.Rect({
            width: this.healthBarWidth(),
            height: 10 * GAME_RATIO,
            fill: 'rgb(150,150,150)',
            originX: 'center',
            originY: 'center'
        })
    }

    createFabricObj(serverTank) {
        return new fabric.Group([this.background, this.healthBar], {
            originX: 'center',
            originY: 'center',
            left: serverTank.position[0] * GAME_RATIO,
            top: (serverTank.position[1] * GAME_RATIO) + HEALTH_OFFSET
        });
    }

    createHealthBar() {
        return new fabric.Rect({
            width: (this.current_health / this.max_health) * this.healthBarWidth(),
            height: 10 * GAME_RATIO,
            fill: this.getColor(),
            originX: 'center',
            originY: 'center'
        })
    }

    healthBarWidth() {
        return FACTOR * this.max_health * GAME_RATIO
    }
}