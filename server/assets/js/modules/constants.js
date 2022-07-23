// Ratio of displayed stuff on the frontend. I.E. If the map is 10 000 x 10 000 and the GAME_RATIO is 0.8, the map will be 8000 units long on the frontend.
export const GAME_RATIO = 0.8
export const LARGE_DEBRIS_RADIUS = 35 * GAME_RATIO;
export const MEDIUM_DEBRIS_RADIUS = 30 * GAME_RATIO;
export const SMALL_DEBRIS_RADIUS = 25 * GAME_RATIO;
export const PROJECTILE_RADIUS = 15 * GAME_RATIO;
export const TANK_RADIUS = 50 * GAME_RATIO
export const HOT_ZONE_RADIUS = 1000 * GAME_RATIO

export const GRID_SIZE = 250 * GAME_RATIO
export const MAP_WIDTH = 5000 * GAME_RATIO
export const MAP_HEIGHT = 5000 * GAME_RATIO
export const MINIMAP_WIDTH = 300
export const MINIMAP_HEIGHT = MINIMAP_WIDTH * MAP_WIDTH / MAP_HEIGHT
export const MAX_ZOOM = 4
export const MIN_ZOOM = 0.05
export const GRID_STROKE = 1 * GAME_RATIO
export const GRID_COLOR = 'rgb(150,150,150)'
export const NAME_OFFSET = -80 * GAME_RATIO
export const HEALTH_OFFSET = 65 * GAME_RATIO
export const HEALTHBAR_WIDTH = 50 * GAME_RATIO
export const SELECTED_TANK_OUTLINE_COLOR = 'rgb(0,255,0)'
// in ms
export const CANVAS_UPDATE_RATE = 1000 / 3
export const ANIMATION_DURATION = 1000 / 3
export const FADE_DURATION = 150
export const COLORS = ['#F60000', '#FF8C00', '#CCBB00', '#4DE94C', '#3783FF', '#4815AA', '#234E85', '#6E7C74', '#C7B763', '#D09D48', '#CA6220', '#C63501', '#777777', '#ABCDEF', '#DCBA98']
export const DEBRIS_TYPE = [1, 2]
export const HOT_ZONE_FILL_COLOR = 'rgba(150, 50, 150, 0.5)'
export const HOT_ZONE_OUTLINE_COLOR = 'rgb(150, 50, 150)'
export function linear(t, b, c, d) {
    return b + (t / d) * c
}
