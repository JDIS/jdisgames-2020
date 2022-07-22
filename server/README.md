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

## Déploiment

### Https

#### Certificat

On va devoir générer un certificat en utilisant Let's Encrypt. On va ensuite devoir mettre le certificate bundle (le certificat + le CA chain) à `/etc/jdisgames2020/cert/cert.pem` et la clé privée à `/etc/jdisgames2020/cert/key.pem`.

#### URL

Il va falloir configurer le host avec la variable d'environnement `DIEP_HOST`.

### Mettre à jour le déploiment

1. Builder une image docker: `docker build . -t ghcr.io/jdis/jdisgames-2020`
1. [Se connecter à Github Container Registry si ce n'est pas déjà fait](#se-connecter-à-github-container-registry)
1. Pousser l'image sur Github Container Registry: `docker push ghcr.io/jdis/jdisgames-2020`
1. Se connecter sur le serveur
1. [Se connecter à Github Container Registry si ce n'est pas déjà fait](#se-connecter-à-github-container-registry)
1. Télécharger l'image: `docker pull ghcr.io/jdis/jdisgames-2020`
1. Naviguer dans le dossier du serveur: `cd /jdisgames-2020/server`
1. Arrêter le serveur: `docker compose stop`
1. Supprimer le container du serveur: `docker rm server-server-1`
1. Repartir le serveur: `docker compose up`

#### Se connecter à Github Container Registry

1. `docker login ghcr.io`
1. username: courriel de son compte github
1. password: un [personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) avec la permission "write:packages"
