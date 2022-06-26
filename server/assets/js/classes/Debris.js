import { fabric } from 'fabric';
import {
    FADE_DURATION,
    LARGE_DEBRIS_RADIUS,
    linear,
    MEDIUM_DEBRIS_RADIUS,
    SMALL_DEBRIS_RADIUS,
    GAME_RATIO,
} from "../modules/constants";
import {regularPolygonPoints} from "../modules/utils";


export class Debris {

    constructor(serverDebris) {
        this.position = {x: serverDebris.position[0] * GAME_RATIO, y: serverDebris.position[1] * GAME_RATIO}
        this.id = serverDebris.id
        this.fabricObj = this.createFabricObj(serverDebris.size)
        this.setAttributes(serverDebris)
    }

    setAttributes(serverDebris) {
        this.current_hp = serverDebris.current_hp
    }

    update(newServerDebris) {
        if (newServerDebris.current_hp !== this.current_hp){
            this.fabricObj.animate('opacity', newServerDebris.current_hp / newServerDebris.max_hp, {
                easing: linear,
                duration: FADE_DURATION,
                onComplete: null,
                onChange: null
            })
        }
        this.setAttributes(newServerDebris)
    }

    die(onComplete) {
        this.fabricObj.animate('opacity', 0, {
            easing: linear,
            duration: FADE_DURATION,
            onComplete: onComplete,
            onChange: null
        })
    }

    createFabricObj(size) {
        let fabricObj;
        switch (size) {
            case "small":
                fabricObj = this.createSmallDebris()
                break
            case "medium":
                fabricObj = this.createMediumDebris()
                break
            case "large":
                fabricObj = this.createLargeDebris()
                break
        }
        fabricObj.left = this.position.x
        fabricObj.top = this.position.y
        return fabricObj

    }

    createSmallDebris() {

        return new fabric.Rect({
            width: SMALL_DEBRIS_RADIUS,
            height: SMALL_DEBRIS_RADIUS,
            angle: parseInt(this.id % BigInt(360)),
            stroke: 'black',
            strokeWidth: 3 * GAME_RATIO,
            fill: 'grey'
        })
    }

    createMediumDebris() {

        return new fabric.Polygon(regularPolygonPoints(3, MEDIUM_DEBRIS_RADIUS), {
            angle: parseInt(this.id % BigInt(360)),
            stroke: 'green',
            strokeWidth: 3 * GAME_RATIO,
            fill: "rgb(200, 255, 100)"
        })
    }

    createLargeDebris() {

        return new fabric.Polygon(regularPolygonPoints(5, LARGE_DEBRIS_RADIUS), {
            angle: parseInt(this.id % BigInt(360)),
            stroke: 'rgb(100, 0, 0)',
            strokeWidth: 3 * GAME_RATIO,
            fill: "rgb(255, 100, 100)"
        })
    }
}