# Lazarus i18n Template

A ready-to-compile, reusable template for building **multilingual desktop  
applications** in **Free Pascal / Lazarus** that run identically on **Windows**  
and **Linux** — using a lightweight, dependency-free `.lang` (INI) localization  
system. *No gettext, no `.po`/`.mo`.*  

Un modèle réutilisable, prêt à compiler, pour créer des **applications de bureau  
multilingues** en **Free Pascal / Lazarus**, fonctionnant à l'identique sous  
**Windows** et **Linux**, grâce à un système de localisation léger et sans
dépendance basé sur des fichiers `.lang` (format INI). *Ni gettext, ni
`.po`/`.mo`.*

**[Français](#francais)** · **[English](#english)**

## Démarrage rapide · Quick start

```bash
git clone <repo-url> lazarus-i18n-template  
cd lazarus-i18n-template  
lazbuild lazarus_i18n_template.lpi    # or open the .lpi in Lazarus and press F9  
./lazarus_i18n_template               # Windows: lazarus_i18n_template.exe
```

---

<a name="francais"></a>
## 🇫🇷 Français

### Présentation

Ce dépôt est un **squelette d'application** que vous pouvez cloner pour démarrer  
n'importe quel logiciel de bureau multilingue. Le cœur est l'unité  
[`src/uLocale.pas`](src/uLocale.pas) et sa classe `TLocaleManager`, qui chargent
les traductions depuis des fichiers `.lang` (INI) rangés dans `locale/`.

* **Détection automatique** de la langue système au démarrage (`LC_ALL`,
  `LC_MESSAGES`, `LANG` → `fr_FR.UTF-8` donne `fr`) ; sous **Windows**, repli sur
  l'API de l'OS (`GetUserDefaultLCID`).
* **Changement de langue à chaud**, sans redémarrer.
* **Mémorisation du choix** : la langue sélectionnée est enregistrée dans la
  config utilisateur et **restaurée au lancement suivant** — priorité **choix
  sauvé → langue OS → anglais**.
* **Repli** systématique vers l'anglais : aucune chaîne d'interface n'est codée
  en dur sans valeur par défaut.
* **Multiplateforme** via la LCL : le même code compile sous Windows et Linux.

### L'application de démonstration

Une petite application générique (pas un lecteur média) qui exerce **toutes** les  
catégories de traduction :  

* un **menu** complet : `Fichier` (Ouvrir, Fichiers récents, Quitter), `Édition`
  (Couper/Copier/Coller/Tout sélectionner), `Options` (**Langue ▸** liste des
  langues, Préférences…), `Aide` (À propos) — avec raccourcis `&` ;
* une **barre d'outils** (Ouvrir, Options, À propos) avec **tooltips** ;
* des **labels**, un champ de saisie avec **texte d'invite** (`TextHint`) ;
* une **barre de statut** (état + langue active) ;
* des **boîtes de dialogue** : confirmation et message de bienvenue avec variable
  (`Bienvenue, %s !`) ;
* un **menu Options ▸ Langue** listant toutes les langues disponibles (coche sur
  la langue active) pour basculer en un clic ;
* un **dialogue Options** avec **sélecteur de langue** (alimenté par
  `AvailableLanguages` / `LanguageNames`) qui bascule la langue **à chaud** et
  **mémorise** le choix ;
* des **messages formatés** démontrant `%s`, `%d` et `%%` (« Progression : 42 % »).

Chaque formulaire possède une procédure `UpdateLocale` appelée au démarrage **et**
à chaque changement de langue.

### Prérequis

| Outil | Version | Remarque |
|-------|---------|----------|
| **Free Pascal (FPC)** | 3.2.0+ | testé avec 3.2.2 |
| **Lazarus / LCL** | 2.0+ | testé avec 3.0 |
| Widgetset Linux | gtk2 (par défaut) | qt5/qt6 fonctionnent aussi |

Sous Linux, installez Lazarus et les en-têtes du widgetset (par ex.
`sudo apt install lazarus` qui tire `gtk2`).

### Structure du projet

```
lazarus-i18n-template/
├── src/
│   ├── uLocale.pas            # moteur de localisation (TLocaleManager) — réutilisable tel quel
│   ├── uConfig.pas            # config persistante : mémorise la langue choisie
│   ├── main.pas / main.lfm    # fenêtre principale (menus, barre d'outils, statut, dialogues)
│   └── frmoptions.pas/.lfm    # dialogue Options + sélecteur de langue (bascule à chaud)
├── locale/                    # 10 langues fournies (mêmes clés partout)
│   ├── en.lang fr.lang de.lang es.lang it.lang
│   ├── ru.lang zh.lang ar.lang
│   └── ary.lang arq.lang      # darija marocaine / algérienne (écriture arabe)
├── lazarus_i18n_template.lpi  # projet Lazarus
├── lazarus_i18n_template.lpr  # programme principal
├── docs/
│   ├── localization.md        # guide complet du système
│   └── add-a-language.md      # tutoriel : ajouter une langue
├── scripts/
│   ├── check-keys.sh          # compare les clés entre fichiers .lang
│   └── copy-locale.sh         # copie locale/ vers un dossier de sortie (optionnel)
├── .github/workflows/
│   └── build.yml              # CI : compile Linux + Windows, vérifie les clés
├── .gitignore
├── LICENSE                    # MIT
└── README.md
```

### Compilation

#### Avec l'IDE Lazarus (Windows et Linux)

1. Ouvrez `lazarus_i18n_template.lpi` dans Lazarus.
2. **Exécuter ▸ Construire** (ou `Maj+F9`), puis **Exécuter ▸ Exécuter** (`F9`).

#### En ligne de commande (`lazbuild`)

```bash
# Linux
lazbuild lazarus_i18n_template.lpi
./lazarus_i18n_template
```

```bat
REM Windows  
lazbuild lazarus_i18n_template.lpi  
lazarus_i18n_template.exe  
```

> **Choisir le widgetset Linux** au besoin : `lazbuild --ws=qt5 …`  
> (par défaut : `gtk2`).

### Le dossier `locale/` doit être à côté de l'exécutable

`TLocaleManager` cherche d'abord `locale/` **à côté du binaire**. Ce projet
**compile l'exécutable à la racine du dépôt**, juste à côté de `locale/` : tout
fonctionne donc sans rien copier.

Si vous changez le dossier de sortie (par ex. `bin/`), copiez-y `locale/` :

* **manuellement**, ou
* via le script fourni :
  ```bash
  scripts/copy-locale.sh bin/x86_64-linux
  ```
* ou en l'attachant comme étape post-build dans Lazarus
  (*Projet ▸ Options ▸ Options du compilateur ▸ Exécuter après*) :
  ```
  $ProjPath()/scripts/copy-locale.sh $ProjPath()/bin/$(TargetCPU)-$(TargetOS)
  ```

Pour une installation système sous Linux, l'engine cherche aussi
`…/share/lazarus-i18n-template/locale/` (voir
[`docs/localization.md`](docs/localization.md)).

### Mémorisation de la langue

Le choix de langue est enregistré dans un petit fichier INI de config  
utilisateur (unité [`src/uConfig.pas`](src/uConfig.pas)) :  

* Linux : `~/.config/lazarus-i18n-template/config.ini`
* Windows : `%APPDATA%\lazarus-i18n-template\config.ini`

```ini
[General]
Language=fr
```

Au démarrage, `TfrmMain.InitializeLanguage` applique, dans l'ordre : **la langue  
sauvée → la langue détectée du système → l'anglais**. Tant qu'aucune langue n'est  
sauvée, la détection système s'applique ; dès que l'utilisateur en choisit une,  
elle est mémorisée et restaurée aux lancements suivants.  

### Langues fournies

10 langues prêtes à l'emploi, toutes avec le même jeu de clés : `en`, `fr`, `de`,
`es`, `it`, `ru`, `zh` (chinois simplifié), `ar`, plus la **darija marocaine**
(`ary`) et **algérienne** (`arq`) en écriture arabe.

> `ary`/`arq` sont des codes ISO 639‑3 (3 lettres) : ces langues sont  
> **sélectionnables** dans le menu/dialogue, mais l'auto‑détection (basée sur  
> 2 lettres) retombe sur `ar`.

### Ajouter une langue

Résumé (détails dans [`docs/add-a-language.md`](docs/add-a-language.md)) :

```bash
cp locale/en.lang locale/pt.lang          # 1. copier la référence
# 2. éditer l'en-tête [Language] : Name=Portuguese - Português, Code=pt, Author=…
# 3. traduire les valeurs (garder les clés, les & et les %s/%d/%%)
scripts/check-keys.sh                      # 4. vérifier la synchro des clés
```

La langue apparaît automatiquement dans **Options ▸ Langue** et est détectée au  
démarrage si `LANG=pt_PT.UTF-8`.  

### Ajouter une chaîne traduisible

1. Ajoutez la clé dans **tous** les fichiers (`en.lang`, `fr.lang`, …), sous la
   bonne section :
   ```ini
   [Label]
   MyLabel=My text
   ```
2. Utilisez-la dans le `UpdateLocale` du formulaire, **avec une valeur par
   défaut anglaise** :
   ```pascal
   lblMine.Caption := Locale.Label_('MyLabel', 'My text');
   ```
3. Lancez `scripts/check-keys.sh` pour confirmer que toutes les langues ont la
   clé.

### Intégration continue

Le workflow [`.github/workflows/build.yml`](.github/workflows/build.yml) compile  
le projet sur **Linux (gtk2)** et **Windows (win32)** à chaque push/PR via  
`lazbuild`, lance `check-keys.sh`, et publie les binaires + `locale/` en artefacts
téléchargeables. C'est aussi ce qui valide la branche de détection OS Windows.

> **Permissions :** le token est restreint à `contents: read` +  
> `artifact-metadata: write` (ce dernier requis depuis 2026 pour publier des  
> artefacts ; déclarer `permissions:` met tout scope non listé à `none`).

### Licence

Sous licence [MIT](LICENSE). Auteur : Nicolas DEOUX (NDXDev@gmail.com).

---

<a name="english"></a>
## 🇬🇧 English

### Overview

This repository is an **application skeleton** you can clone to bootstrap any  
multilingual desktop program. Its core is the unit  
[`src/uLocale.pas`](src/uLocale.pas) and its `TLocaleManager` class, which load
translations from `.lang` (INI) files stored in `locale/`.

* **Automatic detection** of the system language at startup (`LC_ALL`,
  `LC_MESSAGES`, `LANG` → `fr_FR.UTF-8` yields `fr`); on **Windows** it falls back
  to the OS API (`GetUserDefaultLCID`).
* **Live language switching**, no restart required.
* **Remembers your choice**: the selected language is saved to the user config
  and **restored on the next launch** — priority **saved choice → OS language →
  English**.
* **Always falls back** to English: no UI string is hard-coded without a default.
* **Cross-platform** through the LCL: the same code compiles on Windows and Linux.

### The demo application

A small, generic application (not a media player) that exercises **every**  
translation category:  

* a full **menu**: `File` (Open, Recent Files, Exit), `Edit`
  (Cut/Copy/Paste/Select All), `Options` (**Language ▸** list of languages,
  Preferences…), `Help` (About) — with `&` accelerators;
* a **toolbar** (Open, Options, About) with **tooltips**;
* **labels** and an input field with a prompt (**`TextHint`**);
* a **status bar** (state + active language);
* **dialogs**: a confirmation and a welcome message with a variable
  (`Welcome, %s!`);
* an **Options ▸ Language** menu listing every available language (the active one
  ticked) to switch in one click;
* an **Options dialog** with a **language selector** (fed by
  `AvailableLanguages` / `LanguageNames`) that switches language **live** and
  **remembers** the choice;
* **formatted messages** demonstrating `%s`, `%d` and `%%` (“Progress: 42%”).

Each form has an `UpdateLocale` procedure, called at startup **and** on every  
language change.  

### Requirements

| Tool | Version | Note |
|------|---------|------|
| **Free Pascal (FPC)** | 3.2.0+ | tested with 3.2.2 |
| **Lazarus / LCL** | 2.0+ | tested with 3.0 |
| Linux widgetset | gtk2 (default) | qt5/qt6 also work |

On Linux install Lazarus and the widgetset headers (e.g.
`sudo apt install lazarus`, which pulls in `gtk2`).

### Project layout

```
lazarus-i18n-template/
├── src/
│   ├── uLocale.pas            # localization engine (TLocaleManager) — reuse as-is
│   ├── uConfig.pas            # persistent config: remembers the chosen language
│   ├── main.pas / main.lfm    # main window (menus, toolbar, status bar, dialogs)
│   └── frmoptions.pas/.lfm    # Options dialog + language selector (live switch)
├── locale/
│   ├── en.lang fr.lang de.lang es.lang it.lang  # 10 bundled languages
│   ├── ru.lang zh.lang ar.lang                  # (identical key sets)
│   └── ary.lang arq.lang      # Moroccan / Algerian Darija (Arabic script)
├── lazarus_i18n_template.lpi  # Lazarus project
├── lazarus_i18n_template.lpr  # program file
├── docs/
│   ├── localization.md        # full guide to the system
│   └── add-a-language.md      # tutorial: add a language
├── scripts/
│   ├── check-keys.sh          # diff keys between .lang files
│   └── copy-locale.sh         # copy locale/ next to a build output (optional)
├── .github/workflows/
│   └── build.yml              # CI: builds Linux + Windows, checks the keys
├── .gitignore
├── LICENSE                    # MIT
└── README.md
```

### Building

#### With the Lazarus IDE (Windows and Linux)

1. Open `lazarus_i18n_template.lpi` in Lazarus.
2. **Run ▸ Build** (or `Shift+F9`), then **Run ▸ Run** (`F9`).

#### From the command line (`lazbuild`)

```bash
# Linux
lazbuild lazarus_i18n_template.lpi
./lazarus_i18n_template
```

```bat
REM Windows  
lazbuild lazarus_i18n_template.lpi  
lazarus_i18n_template.exe  
```

> **Pick a Linux widgetset** if needed: `lazbuild --ws=qt5 …` (default: `gtk2`).

### The `locale/` folder must sit next to the executable

`TLocaleManager` first looks for `locale/` **next to the binary**. This project
**builds the executable into the repository root**, right next to `locale/`, so
everything works with no copy step.

If you change the output directory (e.g. `bin/`), copy `locale/` there:

* **manually**, or
* with the helper script:
  ```bash
  scripts/copy-locale.sh bin/x86_64-linux
  ```
* or as a Lazarus post-build step
  (*Project ▸ Options ▸ Compiler Options ▸ Execute After*):
  ```
  $ProjPath()/scripts/copy-locale.sh $ProjPath()/bin/$(TargetCPU)-$(TargetOS)
  ```

For a system-wide Linux install the engine also searches
`…/share/lazarus-i18n-template/locale/` (see
[`docs/localization.md`](docs/localization.md)).

### Remembering the language

The chosen language is stored in a small per-user INI config file (unit
[`src/uConfig.pas`](src/uConfig.pas)):

* Linux: `~/.config/lazarus-i18n-template/config.ini`
* Windows: `%APPDATA%\lazarus-i18n-template\config.ini`

```ini
[General]
Language=fr
```

At startup, `TfrmMain.InitializeLanguage` applies, in order: **the saved language
→ the detected OS language → English**. While nothing is saved, OS detection
applies; as soon as the user picks a language it is remembered and restored on  
the following launches.  

### Bundled languages

10 ready-to-use languages, all sharing the same key set: `en`, `fr`, `de`, `es`,
`it`, `ru`, `zh` (Simplified Chinese), `ar`, plus **Moroccan** (`ary`) and
**Algerian** (`arq`) Darija in Arabic script.

> `ary`/`arq` are ISO 639-3 (3-letter) codes: these are **selectable** from the  
> menu/dialog, but auto-detection (2-letter based) falls back to `ar`.

### Adding a language

Summary (details in [`docs/add-a-language.md`](docs/add-a-language.md)):

```bash
cp locale/en.lang locale/pt.lang          # 1. copy the reference
# 2. edit the [Language] header: Name=Portuguese - Português, Code=pt, Author=…
# 3. translate the values (keep keys, & accelerators and %s/%d/%%)
scripts/check-keys.sh                      # 4. verify the keys are in sync
```

The language shows up automatically in **Options ▸ Language** and is detected at  
startup when `LANG=pt_PT.UTF-8`.  

### Adding a translatable string

1. Add the key to **all** files (`en.lang`, `fr.lang`, …) under the right
   section:
   ```ini
   [Label]
   MyLabel=My text
   ```
2. Use it in the form's `UpdateLocale`, **with an English default**:
   ```pascal
   lblMine.Caption := Locale.Label_('MyLabel', 'My text');
   ```
3. Run `scripts/check-keys.sh` to confirm every language has the key.

### Continuous integration

The [`.github/workflows/build.yml`](.github/workflows/build.yml) workflow builds  
the project on **Linux (gtk2)** and **Windows (win32)** on every push/PR with  
`lazbuild`, runs `check-keys.sh`, and publishes the binaries + `locale/` as
downloadable artifacts. This is also what validates the Windows OS-detection  
branch.  

> **Permissions:** the token is restricted to `contents: read` +  
> `artifact-metadata: write` (the latter required since 2026 to publish  
> artifacts; declaring `permissions:` sets every unlisted scope to `none`).

### License

Licensed under the [MIT License](LICENSE). Author: Nicolas DEOUX (NDXDev@gmail.com).

---

## Documentation

* [`docs/localization.md`](docs/localization.md) — architecture, `.lang` format,
  `TLocaleManager` API, naming conventions, format variables, best practices,
  debugging.
* [`docs/add-a-language.md`](docs/add-a-language.md) — step-by-step language
  tutorial.
