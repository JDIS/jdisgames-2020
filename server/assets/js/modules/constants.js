export const LARGE_DEBRIS_RADIUS = 35;
export const MEDIUM_DEBRIS_RADIUS = 30;
export const SMALL_DEBRIS_RADIUS = 25;
export const PROJECTILE_RADIUS = 15;
export const TANK_RADIUS = 35

export const GRID_SIZE = 250
export const MAP_WIDTH = 5000
export const MAP_HEIGHT = 5000
export const MINIMAP_WIDTH = 300
export const MINIMAP_HEIGHT = MINIMAP_WIDTH * MAP_WIDTH / MAP_HEIGHT
export const MAX_ZOOM = 4
export const MIN_ZOOM = 0.05
export const GRID_STROKE = 1
export const GRID_COLOR = 'rgb(150,150,150)'
export const NAME_OFFSET = -70
export const HEALTH_OFFSET = 50
export const HEALTHBAR_WIDTH = 50
export const SELECTED_TANK_OUTLINE_COLOR = 'rgb(0,255,0)'
// in ms
export const CANVAS_UPDATE_RATE = 1000 / 3
export const ANIMATION_DURATION = 1000 / 3
export const FADE_DURATION = 150
export const COLORS = ['#F60000', '#FF8C00', '#CCBB00', '#4DE94C', '#3783FF', '#4815AA', '#234E85', '#6E7C74', '#C7B763', '#D09D48', '#CA6220', '#C63501', '#000000', '#ABCDEF', '#DCBA98']
export const DEBRIS_TYPE = [1, 2]
export function linear(t, b, c, d) {
    return b + (t / d) * c
}
