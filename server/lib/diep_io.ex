defmodule DiepIO do
  @moduledoc """
  DiepIO keeps the contexts that define your domain and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  use Boundary, deps: [Ecto, Ecto.Changeset, Ecto.Query], exports: {:all, except: [Repo]}
end
