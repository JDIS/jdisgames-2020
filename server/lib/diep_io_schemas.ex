defmodule DiepIOSchemas do
  @moduledoc """
  Defines the boundary for Ecto schemas

  This boundary only has access to Ecto schemas (and Ecto.Query which is used by Ecto.Schema)
  """
  use Boundary, deps: [Ecto.Schema, Ecto.Query], check: [in: false, out: true]
end
