defprotocol Diep.Io.Core.Entity do
  alias Diep.Io.Core.Position

  @spec get_position(t) :: Position.t()
  def get_position(entity)
  @spec get_radius(t) :: integer
  def get_radius(entity)
end
