import { fabric } from 'fabric';
import {GAME_RATIO, HOT_ZONE_RADIUS, HOT_ZONE_FILL_COLOR, HOT_ZONE_OUTLINE_COLOR} from "../modules/constants";

export class HotZone {
    constructor(serverHotZone) {
        this.position = serverHotZone.position
        this.toCanvas = this.createFabricObj(serverHotZone)
    }

    createFabricObj(serverHotZone) {
        return new fabric.Circle({
            radius: HOT_ZONE_RADIUS,
            fill: HOT_ZONE_FILL_COLOR,
            stroke: HOT_ZONE_OUTLINE_COLOR,
            strokeWidth: 5 * GAME_RATIO,
            originX: 'center',
            originY: 'center',
            objectCaching: true,
            left: serverHotZone.position[0] * GAME_RATIO,
            top: serverHotZone.position[1] * GAME_RATIO
        })
    }
}
