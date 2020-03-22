defprotocol Diep.Io.Core.Entity do
  alias Diep.Io.Core.Position

  @spec get_position(t) :: Position.t()
  def get_position(entity)

  @spec get_radius(t) :: integer
  def get_radius(entity)

  @spec get_body_damage(t) :: integer
  def get_body_damage(entity)
end
