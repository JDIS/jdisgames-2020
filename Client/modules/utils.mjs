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
    return new Set([...allEntitiesIds].filter(x => !newEntitiesIds.has(x)))
}
