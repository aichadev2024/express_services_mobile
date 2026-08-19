# Express Services — Mobile (Flutter)

Application mobile pour les 3 acteurs terrain d'Express Services : **Livreur**,
**Partenaire résident** et **Particulier**. L'Admin reste sur le back-office
web. Le backend est partagé et inchangé (`express_services_backend`).

## Périmètre

| Profil | Ce qu'il peut faire |
|---|---|
| Livreur (compte) | Se connecter (+ OTP si requis), voir ses commandes assignées, changer leur statut, ouvrir WhatsApp |
| Partenaire résident (pas de compte) | Choisir sa boutique dans la liste, déposer une commande depuis son stock, suivre ses commandes, consulter les stats de stock |
| Particulier (pas de compte) | Déposer une commande avec description libre, suivre sa commande par téléphone |

## Lancer le projet

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

- `10.0.2.2` est l'alias de `localhost` de la machine hôte vu depuis
  l'émulateur Android — utile pour pointer sur un backend lancé en local.
- Sur un appareil physique, remplacez par l'IP locale de la machine
  (ex. `http://192.168.1.x:8080`) ou par l'URL de l'API déployée (Render).
- Sans `--dart-define`, l'app pointe par défaut sur `http://10.0.2.2:8080`.

## Structure

```
lib/
  core/           config API, client Dio + JWT, stockage sécurisé du token, thème, formatters
  models/         miroir Dart des DTOs backend (Commande, Produit, Partenaire, Quartier, User)
  features/
    auth/         login + OTP (Livreur)
    commandes/    repository + widgets partagés (carte de commande)
    livreur/      liste des commandes assignées, détail, changement de statut
    partenaire/   sélection de boutique, dépôt de commande depuis le stock, suivi, stats
    particulier/  dépôt de commande (description libre), suivi par téléphone
  routing/        go_router, avec garde d'accès sur /livreur/*
```

Pas de génération de code (pas de `build_runner`) : modèles et providers
Riverpod sont écrits à la main pour rester simples à maintenir.

## Notes

- Le cleartext HTTP (`http://`) n'est autorisé qu'en build **debug**
  (`android/app/src/debug/AndroidManifest.xml`), pour pointer sur un backend
  local. Un build release doit utiliser une API en HTTPS.
- Publication sur les stores : compte développeur Google Play (25 $, unique)
  et Apple Developer (99 $/an) requis, à la charge du client.
