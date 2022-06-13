# DiepIO

To start your Phoenix server:

- Copy development environment file with `cp .env.dev.example .env.dev`
- Install dependencies with `mix deps.get`
- Create and migrate your database with `mix ecto.setup`
- Generate an HTTPS cert with `mix phx.gen.cert`
- Install Node.js dependencies with `cd assets && npm install`
- Seed users with `mix run priv/repo/seeds.exs`
- Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Configurations

Located in the `config` folder. `dev.exs` is the default.

## Tests

Pour préparer votre environnement à exécuter les tests: `cp .env.test.example .env.test`

Pour exécuter tous les tests sauf les tests temps réel: `mix test`

Pour exécuter uniquement les tests temps réel: `mix test --only RT`

Pour exécuter tous les tests: `mix test --include RT`

## Seeds
To add seeded players, add this before starting the server in entrypoint.sh:

```
echo "Seeding database before starting..."

DIEP_SECRET_KEY_BASE=$(cat secret_key.txt) bin/diep_io eval "DiepIORelease.seed"
```