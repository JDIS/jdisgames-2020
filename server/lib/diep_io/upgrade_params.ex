defmodule DiepIO.UpgradeParams do
  @type t :: %__MODULE__{
          upgrade_rate: float(),
          base_value: number()
        }

  @enforce_keys [:upgrade_rate, :base_value]
  defstruct [:upgrade_rate, :base_value]
end
