/**
 * Module for utility functions that don't fit anywhere else
 */

/**
 * @param entities Object where its key is the same as newEntitiesIds' elements type
 * @param newEntitiesIds List of ids
 * @returns {Set} The difference between the keys of entities and newEntitiesIds
 */
export function getDifference(entities, newEntitiesIds) {
    const allEntitiesIds = new Set(Object.keys(entities))
    return new Set([...allEntitiesIds].filter(x => !newEntitiesIds.has(parseInt(x))))
}

export function regularPolygonPoints(sideCount, radius) {
    var sweep = Math.PI * 2 / sideCount;
    var cx = radius;
    var cy = radius;
    var points = [];
    for (var i = 0; i < sideCount; i++) {
        var x = cx + radius * Math.cos(i * sweep);
        var y = cy + radius * Math.sin(i * sweep);
        points.push({ x: x, y: y });
    }
    return (points);
}
