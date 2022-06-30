import { fabric } from 'fabric';
import {ANIMATION_DURATION, linear, NAME_OFFSET, SELECTED_TANK_OUTLINE_COLOR, TANK_RADIUS, GAME_RATIO} from "../modules/constants";
import {getColorFromId} from "../modules/utils";
import {FabricText} from "./FabricText";
import {HealthBar} from "./HealthBar";


export class Tank {

    constructor(serverTank) {
        this.color = getColorFromId(serverTank.id)
        this.has_died = false
        this.destination = serverTank.destination
        this.target = serverTank.target
        this.fire_rate = serverTank.fire_rate
        this.hp_regen = serverTank.hp_regen
        this.upgrade_tokens = serverTank.upgrade_tokens
        this.projectile_damage = serverTank.projectile_damage
        this.speed = serverTank.speed
        this.max_hp = serverTank.max_hp
        this.body_damage = serverTank.body_damage
        this.current_hp = serverTank.current_hp
        this.upgrade_levels = serverTank.upgrade_levels
        this.position = {x: serverTank.position[0] * GAME_RATIO, y: serverTank.position[1] * GAME_RATIO}
        this.id = serverTank.id
        this.cannon_angle = serverTank.cannon_angle
        this.projectile_time_to_live = serverTank.projectile_time_to_live
        this.body = this.createFabricObj(serverTank)
        this.name = new FabricText(serverTank.name, serverTank.position[0] * GAME_RATIO, (serverTank.position[1] * GAME_RATIO) + NAME_OFFSET)
        this.healthBar = new HealthBar(serverTank)
        this.score = serverTank.score
        this.combatLevel = new FabricText("0", (-5 * GAME_RATIO) + serverTank.position[0] * GAME_RATIO,  (2 * GAME_RATIO) + serverTank.position[1] * GAME_RATIO)
        this.toCanvas = new fabric.Group([this.body, this.name.fabricObj, this.healthBar.toCanvas, this.combatLevel.fabricObj])
        this.destinationLine = this.createDestinationLine()
        this.targetLine = this.createTargetLine()
    }

    left() {
        return this.toCanvas.left
    }

    top() {
        return this.toCanvas.top
    }

    select() {
        this.body.item(0).stroke = SELECTED_TANK_OUTLINE_COLOR
        this.body.item(0).strokeWidth = 6 * GAME_RATIO
        this.body.item(1).stroke = SELECTED_TANK_OUTLINE_COLOR
        this.body.item(1).strokeWidth = 6 * GAME_RATIO
        // Invalidate caching.
        // Needed for a special case where changing lock to a tank in the same viewport as precedent selection.
        this.body.item(0).dirty = true // Invalidate caching
    }

    unselect() {
        this.body.item(0).stroke = 'black'
        this.body.item(0).strokeWidth = 3 * GAME_RATIO
        this.body.item(1).stroke = 'black'
        this.body.item(1).strokeWidth = 3 * GAME_RATIO
        this.body.item(0).dirty = true // Invalidate caching
    }

    setHUDVisible(visibilityState) {
        this.name.fabricObj.visible = visibilityState
        this.healthBar.toCanvas.visible = visibilityState
    }

    update(newServerTank, hitCallback) {
        this.score = newServerTank.score
        this.speed = newServerTank.speed
        this.destination = newServerTank.destination
        this.target = newServerTank.target
        this.hp_regen = newServerTank.hp_regen
        this.body_damage = newServerTank.body_damage
        this.upgrade_tokens = newServerTank.upgrade_tokens
        this.fire_rate = newServerTank.fire_rate
        this.projectile_damage = newServerTank.projectile_damage
        this.position = {x: newServerTank.position[0] * GAME_RATIO, y: newServerTank.position[1] * GAME_RATIO}
        this.upgrade_levels = newServerTank.upgrade_levels
        this.projectile_time_to_live = newServerTank.projectile_time_to_live
        const combatLevel = Object.values(newServerTank.upgrade_levels).reduce((accumulator, value) => accumulator + value)
        this.combatLevel.fabricObj.set('text', combatLevel.toString())

        if (newServerTank.current_hp < this.current_hp && newServerTank.max_hp === this.max_hp) {
            hitCallback(this)
        }

        this.destinationLine.visible = false
        this.targetLine.visible = false

        this.current_hp = newServerTank.current_hp
        this.max_hp = newServerTank.max_hp

        if (this.has_died) {
            this.toCanvas.left = newServerTank.position.x
            this.toCanvas.top = newServerTank.position.y
            this.toCanvas.opacity = 0
            this.toCanvas.animate('opacity', 1, {
                onChange: null,
                duration: ANIMATION_DURATION,
                easing: linear
            })
        } else {
            this.toCanvas.animate('left', this.position.x, {
                onChange: null,
                duration: ANIMATION_DURATION,
                easing: linear
            })
            this.toCanvas.animate('top', this.position.y, {
                onChange: null,
                duration: ANIMATION_DURATION,
                easing: linear
            })
        }

        this.healthBar.update(newServerTank)

        if (newServerTank.cannon_angle !== this.cannon_angle) {
            this.body.animate('angle', newServerTank.cannon_angle, {
                onChange: null,
                duration: ANIMATION_DURATION / 2,
                easing: fabric.util.ease.easeOutQuad
            })
            this.cannon_angle = newServerTank.cannon_angle
        }
        this.has_died = newServerTank.has_died
    }

    updateLines(canvas) {
        canvas.remove(this.destinationLine)
        canvas.remove(this.targetLine)
        this.destinationLine = this.createDestinationLine()
        this.targetLine = this.createTargetLine()
        canvas.add(this.destinationLine)
        canvas.add(this.targetLine)
    }

    createDestinationLine() {
        let destinationX = this.position.x
        let destinationY = this.position.y
        if (this.destination) {
            destinationX = this.destination[0] * GAME_RATIO;
            destinationY = this.destination[1] * GAME_RATIO;
        }
        return new fabric.Line([this.toCanvas.left, this.toCanvas.top, destinationX, destinationY], {
            stroke: this.color,
            originX: 'left',
            originY: 'top',
            strokeWidth: 5 * GAME_RATIO,
            visible: !(this.destination === undefined || this.destination === null)
        })
    }

    createTargetLine() {
        let targetX = this.position.x
        let targetY = this.position.y
        if (this.target) {
            targetX = this.target[0] * GAME_RATIO;
            targetY = this.target[1] * GAME_RATIO;
        }
        return new fabric.Line([this.toCanvas.left, this.toCanvas.top, targetX, targetY], {
            stroke: this.color,
            strokeDashArray: [10 * GAME_RATIO, 15 * GAME_RATIO],
            strokeWidth: 5 * GAME_RATIO,
            originX: 'left',
            originY: 'top',
            visible: !(this.target === undefined || this.target === null)
        })
    }

    createFabricObj(serverTank) {
        const tankCircle = new fabric.Circle({
            radius: TANK_RADIUS,
            fill: this.color,
            stroke: 'black',
            strokeWidth: 3 * GAME_RATIO,
            originX: 'center',
            originY: 'center',
            objectCaching: true

        })
        const tankRect = new fabric.Rect({
            width: 15 * GAME_RATIO,
            height: 27 * GAME_RATIO,
            fill: 'black',
            left: 40 * GAME_RATIO,
            centeredRotation: false,
            originX: 'center',
            originY: 'center',
            objectCaching: true
        })
        const tank = new fabric.Group([tankRect, tankCircle], {
            originX: 'center',
            originY: 'center',
            objectCaching: true
        })

        tank.left = this.position.x
        tank.top = this.position.y
        tank.angle = serverTank.angle

        return tank;
    }
}