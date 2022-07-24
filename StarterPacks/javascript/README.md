# Diep.IO - _Starter Pack_ JavaScript

Ce projet contient tout le nécessaire pour programmer un agent intelligent en JavaScript pour la compétition JDIS Games 2022.

## Dépendances

L'agent a été testé avec la version 16 de NodeJS. Il est possible qu'il fonctionne avec d'autres versions de NodeJS, mais les organisateurs n'offriront aucun support en cas de problème.

Exécutez la commande suivante pour installer les dépendances du projet:

```bash
npm i
```

## Démarrer l'agent

Pour démarrer l'agent, il suffit d'exécuter la commande suivante:

```bash
npm start -- -s <SECRET TOKEN>
```

Assurez-vous de remplacer `<SECRET TOKEN>` avec la clé secrète qui vous a été fournie lors de votre inscription.

Par défaut, le bot se connectera à la partie classée. Il est possible de se connecter à la partie d'entrainement avec l'option `-r`:

```bash
npm start -- -s <SECRET TOKEN> -r
```

## Programmer l'agent

Pour programmer l'agent intelligent, le seul endroit où vous devez écrire du code est la fonction [`tick` dans Bot.js](./Bot.js). Vous pouvez créer de nouvelles méthodes, classes et fichiers à votre convenance, mais une modification de tout autre fichier inclus dans le projet risque fortement de causer des problèmes qui empêcheront le bon fonctionnement de votre agent.

### Typescript

Le code vous est fourni en Javascript afin d'être accessible au plus grand nombre, mais il va de soi que vous êtes libres de le convertir en Typescript si vous désirez faire usage des interfaces fournies dans le dossier `types/`. Il est cependant de votre responsabilité de configurer le projet pour interpréter votre code Typescript.

## Fonctionnement de l'agent

Une fois l'agent et sa partie correspondante démarrés, la fonction `tick` sera automatiquement appelée à intervalles réguliers. Elle recevra en paramètre l'état complet de la partie à ce moment. Voir l'interface [GameState](types/GameState.d.ts) pour plus d'informations sur le contenu de ce paramètre.

La fonction `tick` doit retourner un objet d'action, qui indiquera ce que votre agent doit faire. Voir l'interface [Action](types/Action.d.ts) pour plus d'informations sur le format du retour.

### Comportement en cas d'erreur

Le serveur conservera toujours en mémoire la dernière action valide qu'il a reçue de votre agent. Cela signifie que si votre agent arrête d'envoyer des actions, par exemple parce qu'il est en erreur, celui-ci continuera simplement à effectuer la même action jusqu'à ce que vous réussissiez à en envoyer une nouvelle.

### Gestion des délais

La fonction tick sera appelée 3 fois par seconde. Cela signifie qu'elle devra retourner une action en moins de 333ms environ. Si une nouvelle invocation arrive alors que votre agent est toujours en train de calculer une action, la nouvelle invocation sera simplement ignorée et votre agent continuera son travail normalement.

Par exemple, si votre agent prend 350ms pour calculer une action, 1 mise à jour sur deux sera sautée. Si votre agent prend 900ms pour calculer une action, 2 mises à jour sur 3 seront sautées (vous n'aurez accès qu'à 1 mise à jour par seconde).

**Cela signifie qu'il est de votre responsabilité de surveiller la performance et surtout l'absence de boucles infinies dans votre implémentation**. En cas de problèmes de performance de votre agent, rien ne vous l'indiquera. Vous devrez bâtir vos propres mécanismes de surveillance, par exemple via de la journalisation.
