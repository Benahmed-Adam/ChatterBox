# ChatterBox

Application de messagerie de groupe écrite en Flutter / Dart. Le client parle à une API REST en PHP + MySQL, dans un dépôt séparé : [ChatterBox-Server](https://github.com/Benahmed-Adam/ChatterBox-Server).

## Fonctionnalités

- Inscription et connexion, avec un jeton renvoyé par le serveur pour les requêtes suivantes
- Groupes : création, ajout de membres par recherche de pseudo, renommage, départ
- Envoi et lecture des messages d'un groupe
- Profil : changement de mot de passe, régénération du jeton, suppression du compte
- Choix du serveur dans l'application : plusieurs adresses enregistrées, chacune vérifiée via `/api/test.php` avant d'être utilisée

## Lancer le client

```bash
flutter pub get
flutter run
```

Le serveur utilisé par défaut est défini par `originUrl` dans `lib/api_request.dart`. Pour un serveur local, installer [ChatterBox-Server](https://github.com/Benahmed-Adam/ChatterBox-Server) puis ajouter son adresse depuis les réglages de l'écran d'accueil.

## Structure

```
lib/
├── api_request.dart   # Tous les appels à l'API REST
├── entities/          # User, Group, Message
├── pages/             # Connexion, inscription, accueil, groupe, réglages, profil
├── utils.dart
└── main.dart
```

## Limites connues

- Pas de temps réel : les messages sont rafraîchis en interrogeant le serveur toutes les 2 secondes.
- Testé sur Android uniquement.
