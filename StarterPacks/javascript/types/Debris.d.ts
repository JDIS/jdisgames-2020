export enum DebrisType {
  SMALL = 'small',
  MEDIUM = 'medium',
  LARGE = 'large'
}

export default interface Debris {
  /*
    Debris in the map to be destroyed for points and experience
  */

  id: string
  current_hp: number
  max_hp: number
  size: DebrisType
  position: [number, number]
}
