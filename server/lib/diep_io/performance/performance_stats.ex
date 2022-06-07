defmodule DiepIO.Performance.Stats do
  @enforce_keys [:average, :std_dev, :max]
  defstruct [:average, :std_dev, :max]

  @type t :: %__MODULE__{
          average: float(),
          std_dev: float(),
          max: float()
        }

  @spec new(map() | list()) :: t()
  def new(opts) when is_map(opts) or is_list(opts) do
    %__MODULE__{average: opts[:average], std_dev: opts[:std_dev], max: opts[:max]}
  end
end
