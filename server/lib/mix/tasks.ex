defmodule Mix.Tasks do
  @moduledoc false

  use Boundary, deps: [DiepIOApplication, DiepIO], exports: [], check: [in: false, out: true]
end
