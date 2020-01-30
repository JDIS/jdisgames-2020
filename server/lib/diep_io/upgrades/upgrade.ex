defmodule Diep.Io.Upgrades.Upgrade do
  @moduledoc false

  alias Diep.Io.Tank

  @callback prices() :: [non_neg_integer]
  @callback price(non_neg_integer) :: non_neg_integer
  @callback max_level() :: non_neg_integer
  @callback apply(Tank.t()) :: Tank.t()
end
