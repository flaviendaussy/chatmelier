# Charte de Versionnage, Changelogs et Communication Utilisateur — Chatmelier

Ce document définit les règles strictes et immuables régissant le cycle de versions de Chatmelier, la tenue du fichier `CHANGELOG.md`, ainsi que les critères éditoriaux de communication lors de chaque mise à jour.

---

## 1. Règle de Versionnage Sémantique (SemVer)

Le numéro de version suit la norme **`vMAJOR.MINOR.PATCH+BUILD`** (déclaré dans `app/pubspec.yaml`) :

- **`MAJOR`** (ex: `1.0.0` -> `2.0.0`) :
  - Refonte visuelle majeure ou ergonomique globale.
  - Changement d'architecture fondamentale ou rupture de compatibilité non rétrocompatible.
- **`MINOR`** (ex: `1.1.0` -> `1.2.0`) :
  - Ajout d'une fonctionnalité significative (ex: module équipement cocktail & shaker maison, carte interactive des terroirs, système de badges, OCR de menu).
  - Évolution sensible de l'expérience utilisateur ou nouveaux modules métier.
- **`PATCH`** (ex: `1.2.0` -> `1.2.1`) :
  - Résolution de bugs, corrections d'affichages ou de calculs (ex: échelle de note 10/10).
  - Ajustements de mise en page, gains d'espace, renommage d'onglets, ergonomie fine.
  - Renforcement de la résilience offline, synchronisation ou optimisation des publicités.
- **`BUILD`** (ex: `+41` -> `+42`) :
  - Entier incrémental strictement croissant à chaque génération d'un livrable APK / bundle.
  - Permet à Android de reconnaître la mise à jour et d'écraser proprement l'ancienne version.

---

## 2. Règle de Tenue du `CHANGELOG.md`

À chaque mise à jour, une nouvelle entrée doit impérativement être ajoutée au sommet du fichier `CHANGELOG.md` à la racine du projet, respectant la structure suivante :

```markdown
## [vX.Y.Z+B] — AAAA-MM-JJ

### 🍷 Ce qui change pour vous
- **[Nom de la nouveauté]** : Explication claire en 1 phrase du bénéfice.
- **[Amélioration]** : Ce qui devient plus simple ou plus agréable au quotidien.
- **[Correctif visible]** : Ce qui a été réparé pour l'utilisateur sans aucun jargon.

### 🛠️ Notes Techniques (Développeurs)
- *Composant / Fichier* : Détails des changements de code, requêtes SQL, fallbacks, hooks et dépendances.
```

---

## 3. Protocole de Communication Utilisateur (Update Notes / Modale)

Lorsqu'une mise à jour est communiquée aux utilisateurs (via une pop-up in-app, un message de mise à jour, ou la note de version du store) :

### 🎯 Objectif
Fournir une vision immédiate, rassurante et valorisante de ce qui change, sans noyer l'utilisateur sous des détails techniques.

### 📜 Les 4 Règles d'Or :
1. **Règle des 3-4 points maximum** :
   - Jamais plus de 3 points pour les nouveautés et 1 à 2 points pour les correctifs majeurs.
   - Lecture complète en moins de 15 secondes.
2. **Langage axé utilisateur et valeur** :
   - Parler de *ce que l'utilisateur peut faire* ou de *ce qu'il voit*.
   - Ex : *"Votre note s'affiche désormais fidèlement sur 10/10 dans votre journal"* (et non : *"Normalisation du champ rating de TastingEntry avec displayRating"*).
3. **Zéro jargon technique** :
   - Proscrits : noms de colonnes SQL (`bottle_owner_id`), codes HTTP/REST (`PGRST204`), concepts de framework (`StateNotifier`, `Completer`, `SharedPreferences`, `addPostFrameCallback`, `Lifecycle`).
   - Remplacer par : "sauvegarde sécurisée", "synchronisation automatique", "affichage optimisé", "protection hors-ligne".
4. **Ton chaleureux et élégant** :
   - En adéquation avec l'univers du vin et de la dégustation (plaisir, convivialité, précision sans prétention).

### 📋 Gabarit de Message Utilisateur :
> **Nouveautés dans Chatmelier (vX.Y.Z) ✨**
> 
> - 🍇 **[Nouveauté clé 1]** : [Bénéfice immédiat]
> - 📱 **[Nouveauté clé 2 ou ergonomie]** : [Bénéfice immédiat]
> - 🛠️ **[Correctif utile]** : [Ce qui a été réparé simplement]
> 
> *Bonne dégustation !*
