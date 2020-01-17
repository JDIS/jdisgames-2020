{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  elixir = beam.packages.erlangR22.elixir_1_9;
  nodejs = nodejs-12_x;
in

mkShell {
  buildInputs = [ elixir nodejs git inotify-tools ];
}