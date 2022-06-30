import { fabric } from 'fabric';
import { GAME_RATIO } from '../modules/constants';

export class FabricText {

    constructor(text, x, y) {
        this.text = text
        this.fabricObj = this.createFabricObj(x, y);

    }

    createFabricObj(x, y) {
        return new fabric.Text(this.text, {
            left: x,
            top: y,
            fontSize: 35 * GAME_RATIO,
            fontFamily: 'Sans-Serif',
            originX: 'center',
            originY: 'center'
        })
    }
}