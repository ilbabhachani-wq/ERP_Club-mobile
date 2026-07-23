# ERP Club — Application Mobile Joueur (Flutter)

Application mobile SaaS dédiée au **rôle Joueur**, avec le même design ODIN (glassmorphism, couleurs, animations) que le frontend web.

## Parcours de lancement

1. **Splash natif** — fond `#0B0B14` (Android/iOS) pendant le chargement Flutter
2. **Splash animé** — logo ODIN, anneaux rotatifs, particules, barre de progression
3. **Onboarding** (1ère ouverture) — 4 slides animés avec illustrations custom
4. **Login** → Dashboard

Pour revoir l'onboarding (debug) :

```dart
await OnboardingService().reset();
```

## Fonctionnalités

| Écran | Route |
|-------|-------|
| Dashboard (carte FIFA, KPIs, activité) | `/` |
| Performances (radar, notes match) | `/performances` |
| Planning (calendrier, countdown) | `/planning` |
| AI Coach (chat + rapport) | `/ai` |
| Menu (accès à tous les écrans) | `/menu` |
| Médical | `/medical` |
| Profil & contrat | `/profil` |
| Messages | `/messages` |
| Effectif | `/liste` |
| Comparer | `/comparer` |
| Formation 4-3-3 | `/formation` |
| Transferts | `/transferts` |
| Documents | `/documents` |
| Entraînement | `/entrainement` |
| Analyse match | `/analyse` |
| Récompenses | `/recompenses` |
| Chimie | `/chimie` |
| **Viiv GX17 Smartwatch** | `/viiv` |

## Prérequis

- Flutter 3.38+
- Xcode (iOS) / Android Studio (Android)

## Installation

```bash
cd mobile
flutter pub get
flutter run
```

## Configuration API

Par défaut, l'app pointe vers le backend de production (sans `/api` — le proxy web le retire, l'app mobile appelle directement) :

```
https://erp-club-backend-production.up.railway.app
```

Pour un backend local :

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

## Connexion

Utilisez un compte avec le rôle **Joueur** (ex. `joueur@club.com`).

## Structure

```
lib/
  config/          # URL API
  core/            # Theme, animations, widgets (GlassCard, FIFA card…)
  models/          # Modèles de données
  services/        # API client, auth, endpoints joueur/club
  providers/       # State management (Provider)
  screens/         # Tous les écrans joueur
  shell/           # Navigation bottom bar
  router/          # GoRouter
```
