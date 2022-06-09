defmodule Mix.Tasks do
  use Boundary, deps: [DiepIOApplication, DiepIO], exports: [], check: [in: false, out: true]
end
