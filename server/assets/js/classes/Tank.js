import {ANIMATION_DURATION, linear, NAME_OFFSET, SELECTED_TANK_OUTLINE_COLOR, TANK_RADIUS} from "../modules/constants";
import {getColorFromId} from "../modules/utils";
import {FabricText} from "./FabricText";
import {HealthBar} from "./HealthBar";


export class Tank {

    constructor(serverTank) {
        this.color = getColorFromId(serverTank.id)
        this.has_died = false
        this.fire_rate = serverTank.fire_rate
        this.upgrade_tokens = serverTank.upgrade_tokens
        this.projectile_damage = serverTank.projectile_damage
        this.speed = serverTank.speed
        this.max_hp = serverTank.max_hp
        this.body_damage = serverTank.body_damage
        this.current_hp = serverTank.current_hp
        this.upgrade_levels = serverTank.upgrade_levels
        this.position = {x: serverTank.position[0], y: serverTank.position[1]}
        this.id = serverTank.id
        this.cannon_angle = serverTank.cannon_angle
        this.body = this.createFabricObj(serverTank)
        this.name = new FabricText(serverTank.name, serverTank.position[0], serverTank.position[1] + NAME_OFFSET)
        this.healthBar = new HealthBar(serverTank)
        this.score = serverTank.score
        this.toCanvas = new fabric.Group([this.body, this.name.fabricObj, this.healthBar.toCanvas])
    }

    left() {
        return this.toCanvas.left
    }

    top() {
        return this.toCanvas.top
    }
    
    select() {
        this.body.item(0).stroke = SELECTED_TANK_OUTLINE_COLOR
        this.body.item(0).strokeWidth = 6
        this.body.item(1).stroke = SELECTED_TANK_OUTLINE_COLOR
        this.body.item(1).strokeWidth = 6
        // Invalidate caching.
        // Needed for a special case where changing lock to a tank in the same viewport as precedent selection.
        this.body.item(0).dirty = true // Invalidate caching
    }
    
    unselect() {
        this.body.item(0).stroke = 'black'
        this.body.item(0).strokeWidth = 3
        this.body.item(1).stroke = 'black'
        this.body.item(1).strokeWidth = 3
        this.body.item(0).dirty = true // Invalidate caching
    }

    setHUDVisible(visibilityState) {
        this.name.fabricObj.visible = visibilityState
        this.healthBar.toCanvas.visible = visibilityState
    }

    update(newServerTank) {
        this.score = newServerTank.score
        this.speed = newServerTank.speed
        this.body_damage = newServerTank.body_damage
        this.upgrade_tokens = newServerTank.upgrade_tokens
        this.fire_rate = newServerTank.fire_rate
        this.projectile_damage = newServerTank.projectile_damage
        this.position = {x: newServerTank.position[0], y: newServerTank.position[1]}
        this.max_hp = newServerTank.max_hp
        this.current_hp = newServerTank.current_hp
        this.upgrade_levels = newServerTank.upgrade_levels

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

    createFabricObj(serverTank) {
        const tankCircle = new fabric.Circle({
            radius: TANK_RADIUS,
            fill: this.color,
            stroke: 'black',
            strokeWidth: 3,
            originX: 'center',
            originY: 'center',
            objectCaching: true

        })
        const tankRect = new fabric.Rect({
            width: 15,
            height: 27,
            fill: 'black',
            left: 30,
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