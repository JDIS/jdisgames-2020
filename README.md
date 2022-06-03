![pipeline status](https://github.com/JDIS/jdisgames-2020/workflows/Continuous%20Integration/badge.svg?branch=master)
![test-realtime status](https://github.com/JDIS/jdisgames-2020/workflows/Test%20real-time%20constraints/badge.svg?branch=master)

[![coverage report](https://depot.dinf.usherbrooke.ca/dinf/projets/h20/eq02-jdisgames/diep.io/badges/master/coverage.svg)](https://depot.dinf.usherbrooke.ca/dinf/projets/h20/eq02-jdisgames/diep.io/commits/master)
[![max iteration time](https://depot.dinf.usherbrooke.ca/dinf/projets/h20/eq02-jdisgames/diep.io/-/jobs/artifacts/master/raw/server/badges/max_iteration_time.svg?job=generate_badges)](https://depot.dinf.usherbrooke.ca/dinf/projets/h20/eq02-jdisgames/diep.io/commits/master)
[![broadcast std dev](https://depot.dinf.usherbrooke.ca/dinf/projets/h20/eq02-jdisgames/diep.io/-/jobs/artifacts/master/raw/server/badges/broadcast_std_dev.svg?job=generate_badges)](https://depot.dinf.usherbrooke.ca/dinf/projets/h20/eq02-jdisgames/diep.io/commits/master)

# JDIS Games 2020

## Démarrage

Besoin de docker et docker-compose pour démarrer.

`cd server`

`docker-compose up`

Le serveur sera disponible à l'adresse http://localhost:4000.

## Utilisation

### Pages du client web

- **/**

  Page d'accueil de l'application. Cette page est présentement vide, mais sera éventuellement remplie d'informations utiles pour les participants de la compétition.

- **/admin**

  Page d'administration de la compétition. Le nom d'utilisateur et le mot de passe sont tous les deux "admin". Permet de démarrer, arrêter le redémarrage automatique et terminer la partie.

- **/spectate**

  Permet de visualiser la partie en cours.

- **/scoreboard**

  Permet de consulter le tableau des scores pour l'entièreté de la compétition.

- **/team-registration**

  Permet d'inscrire une équipe pour la compétition.

### Préparation et démarrage d'une partie

Avant de démarrer une partie, il est recommandé d'inscrire au moins une équipe à la compétition. Après l'inscription, prenez soin de noter la clé d'authentification qui vous sera donnée. Vous en aurez besoin pour connecter un agent intelligent au serveur.

Une fois une ou plusieurs équipes inscrites, vous pouvez vous rendre dans la page d'administration pour démarrer la partie. Spécifiez tout d'abord le nombre de «ticks» (le serveur exécute 15 «ticks» par seconde), puis démarrez la partie.

Une fois la partie démarrée, vous pouvez vous rendre dans les pages de visualisation de la partie ou du tableau des scores.

### Connection d'un agent au serveur

L'agent inclus dans le projet est écrit en Python. Voir [ici](https://www.python.org/downloads/) pour le télécharger si nécessaire. L'agent a été testé avec les versions 3.7 et 3.8.

Pour démarrer l'agent, rendez-vous dans le dossier `StarterPacks/python` puis exécutez la commande suivante :

```
python run_bot.py {secret_key}
```

L'agent se connectera au serveur et enverra périodiquement des actions au serveur.

Il est possible de démarrer plusieurs agents simultanément avec des clés secrètes différentes pour simuler plusieurs équipes.

## Développement

Pour apporter des modifications ou pour exécuter le serveur dans un environnement de développement, il faut d'abord installer [Elixir](https://elixir-lang.org/install.html) (version 1.13.4) et [PostgreSQL](https://www.postgresql.org/download/) (n'importe quelle version récente).

Une fois ces dépendances installées, assurez-vous d'avoir une base de données PostgreSQL accessible avec les paramètres suivants :

- **nom d'utilisateur** : postgres
- **mot de passe** : postgres
- **nom de la base de données** : diep_io_dev

Le reste des instructions de développement sont disponibles dans le [fichier README du serveur](server/README.md).
