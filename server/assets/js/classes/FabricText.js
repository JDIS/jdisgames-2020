import { fabric } from 'fabric';

export class FabricText {

    constructor(text, x, y) {
        this.text = text
        this.fabricObj = this.createFabricObj(x, y);

    }

    createFabricObj(x, y) {
        return new fabric.Text(this.text, {
            left: x,
            top: y,
            fontSize: 35,
            fontFamily: 'Sans-Serif',
            originX: 'center',
            originY: 'center'
        })
    }
}