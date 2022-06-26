import { fabric } from "fabric";
import {ANIMATION_DURATION, FADE_DURATION, linear, PROJECTILE_RADIUS, GAME_RATIO} from "../modules/constants";


export class Projectile {

    constructor(tankOwner, serverProjectile) {
        this.position = {x: tankOwner.toCanvas.left, y: tankOwner.toCanvas.top}
        this.owner = tankOwner
        this.id = serverProjectile.id
        this.fabricObj = this.createFabricObj(serverProjectile.size)
    }

    update(newServerProjectile) {
        this.fabricObj.animate('left', newServerProjectile.position[0] * GAME_RATIO, {
            onChange: null,
            duration: ANIMATION_DURATION,
            easing: linear
        })
        this.fabricObj.animate('top', newServerProjectile.position[1] * GAME_RATIO, {
            onChange: null,
            duration: ANIMATION_DURATION,
            easing: linear
        })
    }

    die(onComplete) {
        this.fabricObj.animate('opacity', 0, {
            easing: linear,
            duration: FADE_DURATION,
            onComplete: onComplete,
            onChange: null
        })
    }

    createFabricObj() {
        return new fabric.Circle({
            radius: PROJECTILE_RADIUS,
            fill: this.owner.color,
            stroke: 'black',
            strokeWidth: 3 * GAME_RATIO,
            left: this.position.x,
            top: this.position.y,
            originX: 'center',
            originY: 'center'
        })
    }
}