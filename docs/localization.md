# Localization system — developer guide

This template ships a small, self-contained internationalization (i18n) engine:  
a single unit, `src/uLocale.pas`, plus one `.lang` file per language in  
`locale/`. There is **no** gettext, no `.po`/`.mo`, and no external dependency —
just an INI reader wrapped in a friendly API.

Its public API (`TLocaleManager`, the `Locale` function and the `_T` shortcut) is  
intentionally small and kept stable, so you can drop the engine into your own  
projects unchanged.  

**Contents:**
[1. Architecture](#1-architecture) ·
[2. Detection](#2-automatic-language-detection) ·
[3. Search paths](#3-where-lang-files-are-searched) ·
[4. `.lang` format](#4-lang-file-format) ·
[5. Startup & switching](#5-startup-the-updatelocale-pattern-and-hot-switching) ·
[6. Naming](#6-naming-conventions) ·
[7. Best practices](#7-best-practices) ·
[8. API](#8-tlocalemanager-api) ·
[9. Debugging](#9-debugging)

---

## 1. Architecture

```
your-app(.exe)  
locale/  
├── en.lang     ← English (default / fallback language)
├── fr.lang     ← French
└── xx.lang     ← any other language
```

The template ships **10 languages**: `en`, `fr`, `de`, `es`, `it`, `ru`, `zh`
(Simplified Chinese), `ar`, plus Moroccan (`ary`) and Algerian (`arq`) Darija in
Arabic script — all with identical key sets.

* Translations live in `.lang` files written in **INI format**.
* A single manager, `TLocaleManager`, loads one file at a time and answers
  lookups by `(Section, Key)`.
* A process-wide instance is exposed through the global `Locale` function
  (created lazily on first use, freed automatically at shutdown).

```pascal
uses uLocale;

Caption := Locale.Menu('File', '&File');       // [Menu] File=...  
ShowMessage(Locale.Dialog('Welcome', 'Hi'));   // [Dialog] Welcome=...  
```

---

## 2. Automatic language detection

At startup `TLocaleManager` reads the system language, in this order:

1. `LC_ALL`
2. `LC_MESSAGES`
3. `LANG`
4. *(Windows only)* the OS user language via the Win32 API, when none of the
   environment variables above are set

The first non-empty value is reduced to its two-letter code
(`fr_FR.UTF-8` → `fr`). If `locale/fr.lang` exists it is loaded; otherwise the
engine falls back to English.

> **OS detection is only the default.** Once the user has chosen a language it is  
> saved and takes priority over the environment on the next launch — see  
> [§5 Choosing the language at startup](#choosing-the-language-at-startup).

> **Windows:** `LANG`/`LC_*` are POSIX variables that native Windows does not  
> populate, so `DetectOSLanguage` falls back to the OS user language via  
> `GetUserDefaultLCID` + `GetLocaleInfoW` (`LOCALE_SISO639LANGNAME`). This is  
> guarded by `{$IFDEF WINDOWS}`, needs no extra package, and leaves the public API  
> and the Unix path untouched. Environment variables still win when present (e.g.  
> under MSYS2/Cygwin/WSL).

---

## 3. Where `.lang` files are searched

`TLocaleManager.Create` looks for the `locale/` folder in this order and keeps
the first match:

| # | Location | Typical use |
|---|----------|-------------|
| 1 | `<exe>/locale/` | Windows, Linux portable, **development** |
| 2 | `<exe>/lang/` | alternative portable layout |
| 3 | `<exe>/../Resources/locale/` | macOS app bundle |
| 4 | `<exe>/../share/lazarus-i18n-template/locale/` | standard Linux install (`/usr/bin` → `/usr/share`) |
| 5 | `$SNAP/share/lazarus-i18n-template/locale/` | Snap package |
| 6 | `/app/share/lazarus-i18n-template/locale/` | Flatpak |
| 7 | `/usr/share/…` and `/usr/local/share/…` | system-wide fallback |

If nothing matches it falls back to `<exe>/locale/`. The active path is exposed  
as `Locale.LangPath` (handy for debugging).  

> **Rename it for your app:** replace the `lazarus-i18n-template` path segment in  
> `uLocale.pas` (steps 4–7) with your own application id when you install  
> system-wide. Steps 1–2 (next to the executable) need no change and cover local  
> development and portable builds.

---

## 4. `.lang` file format

### Required header: `[Language]`

Every file **must** start with this section:

```ini
[Language]
Name=English  
Code=en  
Author=Your Name  
```

| Key | Description |
|-----|-------------|
| `Name` | Display name shown in the language menu and selector. Convention: **`English name - Endonym`** (e.g. `French - Français`, `German - Deutsch`); `en.lang` is the exception and uses just `English` |
| `Code` | Language code, must match the file name. Usually ISO 639-1 (2 letters: `en`, `fr`, …); 3-letter ISO 639-3 codes also work (`ary`, `arq`) but are selectable only — OS auto-detection reads the first 2 letters, so `ary`/`arq` fall back to `ar` |
| `Author` | Translation author (free text) |

`TLocaleManager.ScanAvailableLanguages` reads `Name` from each file to build the
`AvailableLanguages` / `LanguageNames` lists that feed the Options combo box.

### Translation sections

| Section | Purpose | Shortcut method |
|---------|---------|-----------------|
| `[Menu]` | Menu item captions | `Locale.Menu(Key, Default)` |
| `[Dialog]` | Dialog titles / prompts / filters | `Locale.Dialog(Key, Default)` |
| `[Status]` | Status-bar messages | `Locale.Status(Key, Default)` |
| `[Message]` | Formatted / OSD messages | `Locale.Message(Key, Default)` |
| `[Button]` | Button captions | `Locale.Button(Key, Default)` |
| `[Tooltip]` | Tooltips / hints | `Locale.Tooltip(Key, Default)` |
| `[Label]` | Generic labels | `Locale.Label_(Key, Default)` |
| *(any)* | e.g. `[Options]`, `[About]` | `Locale.GetString(Section, Key, Default)` |

A comment starts with `;` and runs to the end of the line. Use comments to group  
related keys:  

```ini
[Menu]
; File menu
File=&File  
FileOpen=&Open File...  
FileExit=E&xit  

; Edit menu
Edit=&Edit  
EditCopy=&Copy  
```

> The shortcut methods (`Menu`, `Dialog`, …) are just thin wrappers around  
> `GetString` with a fixed section name. Anything they can do, `GetString` can do  
> too — use it for your own sections such as `[Options]` and `[About]`.

---

## 5. Startup, the `UpdateLocale` pattern and hot switching

### Choosing the language at startup

`TfrmMain.InitializeLanguage` (called from `OnCreate`, before the first
`UpdateLocale`) decides which language to load, in this priority order:

1. the **saved** language from the configuration (the user's last choice);
2. otherwise the **OS** language detected by `TLocaleManager`;
3. otherwise **English**.

```pascal
procedure TfrmMain.InitializeLanguage;  
var  
  Lang: string;
begin
  Lang := Config.Language;                          // empty until the user picks one
  if Lang = '' then
    if Locale.AvailableLanguages.IndexOf(Locale.CurrentLanguage) >= 0 then
      Lang := Locale.CurrentLanguage                // OS-detected
    else
      Lang := 'en';
  Locale.LoadLanguage(Lang);
end;
```

See [Remembering the choice](#remembering-the-choice-uconfig) below for how the  
preference is stored and restored.  

### Applying the strings — `UpdateLocale`

Every form owns a public `UpdateLocale` method that re-applies **all** of its  
visible strings from the active language:  

```pascal
procedure TfrmMain.UpdateLocale;  
begin  
  Caption          := Locale.Label_('AppTitle', 'Lazarus i18n Template');
  mnuFile.Caption  := Locale.Menu('File', '&File');
  btnGreet.Caption := Locale.Button('Greet', 'Greet');
  edtName.TextHint := Locale.Label_('NameHint', 'Type your name here');
  // …re-apply every caption, hint, status text, formatted label, etc.
end;
```

Call it:

* **once at startup**, from each form's `OnCreate`; and
* **again on every language change**, so the change is visible immediately
  without restarting.

### How the live switch is wired

The Options dialog (`src/frmoptions.pas`) does **not** know about the rest of the  
app. It exposes an `OnLanguageApply` callback that the host assigns:  

```pascal
// frmoptions.pas — the dialog only raises the event
procedure TfrmOptions.btnApplyClick(Sender: TObject);  
begin  
  if Assigned(FOnLanguageApply) then
    FOnLanguageApply(Self);
end;

// main.pas — the host switches, persists the choice, and refreshes every form
procedure TfrmMain.DoLanguageApply(Sender: TObject);  
begin  
  Locale.LoadLanguage(OptionsForm.SelectedLanguageCode);
  Config.Language := OptionsForm.SelectedLanguageCode; // remember…
  Config.Save;                                         // …and persist it now
  UpdateLocale;             // refresh the main window
  OptionsForm.UpdateLocale; // refresh the dialog itself
end;
```

`SelectedLanguageCode` maps the combo selection back to a code because
`AvailableLanguages[i]` and `LanguageNames[i]` are parallel lists:

```pascal
function TfrmOptions.SelectedLanguageCode: string;  
begin  
  Result := Locale.AvailableLanguages[cmbLanguage.ItemIndex];
end;
```

### The Options ▸ Language menu

The same switch is also offered as a checkable submenu, rebuilt by
`TfrmMain.UpdateLanguageMenu` — one `RadioItem` per available language (sorted by
display name), the current one ticked:

```pascal
Item := TMenuItem.Create(MainMenu1);  
Item.Caption   := Locale.LanguageNames[Index];          // endonym, not translated  
Item.Tag       := Index;                                // maps to AvailableLanguages  
Item.RadioItem := True;  
Item.Checked   := (Locale.AvailableLanguages[Index] = Locale.CurrentLanguage);  
Item.OnClick   := @OnLanguageClick;  
```

`OnLanguageClick` does the same load + persist as the dialog, then defers the
refresh so the clicked item is not freed during its own click:

```pascal
Locale.LoadLanguage(Code);  
Config.Language := Code;  Config.Save;  
Application.QueueAsyncCall(@AsyncApplyLocale, 0);  // UpdateLocale rebuilds this menu  
```

`UpdateLanguageMenu` is called from `UpdateLocale`, so the tick mark and the
language names refresh automatically on every language change.

### Remembering the choice (`uConfig`)

The preference lives in [`../src/uConfig.pas`](../src/uConfig.pas), a small,  
extensible configuration object persisted as INI in the per-user config  
directory:  

| OS | File |
|----|------|
| Linux | `~/.config/lazarus-i18n-template/config.ini` |
| Windows | `%APPDATA%\lazarus-i18n-template\config.ini` |

```ini
[General]
Language=fr
```

```pascal
uses uConfig;

Config.Language;            // saved code; '' means "no preference, detect the OS"  
Config.Language := 'fr';    // set…  
Config.Save;                // …and write the INI now  
```

An empty `Language` means *no preference yet*, which is why a fresh install  
follows OS detection (§2). To persist more settings, add fields to `TConfig` and  
read/write them in `Load`/`Save` exactly like `Language`.  

---

## 6. Naming conventions

### Menu keys — `[Parent][Action]`

```ini
[Menu]
File=&File  
FileOpen=&Open File...  
FileRecent=&Recent Files  
FileExit=E&xit  
Edit=&Edit  
EditCopy=&Copy  
```

### Action / shortcut keys — `Act[ActionName]`

If you add a keyboard-shortcuts editor, name its action labels with an `Act`  
prefix in a dedicated `[Shortcuts]` section:  

```ini
[Shortcuts]
ActPlayPause=Play / Pause  
ActStop=Stop  
ActFullscreen=Fullscreen  
```

### Alt accelerators — `&`

`&` marks the Alt accelerator letter; it is part of the translated value because
the chosen letter differs per language:

```ini
FileOpen=&Open File...   ; en → Alt+O  
FileOpen=&Ouvrir...      ; fr → Alt+O  
```

To print a literal ampersand, double it: `&&`.

### Format variables — `%s %d %f` and `%%`

Dynamic values use Free Pascal's `Format`:

```ini
[Dialog]
Welcome=Welcome, %s!
[Message]
ProgressFormat=Progress: %d%%  
SummaryFormat=Hello %s — %d character(s), %d%% done  
```

```pascal
ShowMessage(Format(Locale.Dialog('Welcome', 'Welcome, %s!'), [UserName]));  
lbl.Caption := Format(Locale.Message('ProgressFormat', 'Progress: %d%%'), [Pos]);  
```

* `%s` string, `%d` integer, `%f` float (`%.2f` = two decimals).
* **`%%` prints a literal percent sign.**
* **Keep the placeholders and their order identical in every translation** — only
  the surrounding words change.

---

## 7. Best practices

1. **Always pass a default** (in English) as the last argument. It is shown if the
   key is missing, so the UI never breaks:
   ```pascal
   Locale.Menu('FileOpen', '&Open File...');   // good
   Locale.Menu('FileOpen', '');                // bad: no fallback
   ```
2. **Keys stay in English**, values get translated. Never translate a key.
3. **Comment and group** related keys (`; File menu`, `; Edit menu`).
4. **Keep every file in sync** — same set of keys everywhere. Verify with
   `scripts/check-keys.sh` (see §9).
5. Put each translatable string in **one** `UpdateLocale` so a language change
   re-applies it.

---

## 8. `TLocaleManager` API

```pascal
TLocaleManager = class
  function LoadLanguage(const LangCode: string): Boolean;
  function GetString(const Section, Key: string; const Default: string = ''): string;

  function Menu(const Key: string; const Default: string = ''): string;
  function Dialog(const Key: string; const Default: string = ''): string;
  function Status(const Key: string; const Default: string = ''): string;
  function Button(const Key: string; const Default: string = ''): string;
  function Label_(const Key: string; const Default: string = ''): string;  // trailing _: Label is reserved
  function Message(const Key: string; const Default: string = ''): string;
  function Tooltip(const Key: string; const Default: string = ''): string;

  property CurrentLanguage: string;          // active code, e.g. 'fr'
  property AvailableLanguages: TStringList;  // ['en', 'fr', …]
  property LanguageNames: TStringList;       // ['English', 'Français', …]
  property LangPath: string;                 // resolved locale/ folder
end;

function Locale: TLocaleManager;             // global instance  
function _T(const Section, Key: string; const Default: string = ''): string;  
```

`_T` is a free-function alias for `Locale.GetString`:

```pascal
Caption := _T('About', 'Title', 'About');
```

---

## 9. Debugging

```pascal
WriteLn('Current language: ', Locale.CurrentLanguage);  
WriteLn('Locale path     : ', Locale.LangPath);  

for I := 0 to Locale.AvailableLanguages.Count - 1 do
  WriteLn(Locale.AvailableLanguages[I], ' = ', Locale.LanguageNames[I]);

WriteLn(Locale.GetString('Menu', 'FileOpen', '*** MISSING ***'));
```

* Nothing translated? Check `Locale.LangPath` actually points at your `locale/`
  folder (it must sit next to the executable during development).
* A single string falls back to English? The key is missing or empty in that
  language file — run the key check below.
* Accented or non-Latin characters look garbled? Save the `.lang` file as
  **UTF-8 without BOM** (FPC's `TIniFile` reads the bytes as-is).
* On Windows the detected language looks off? `DetectOSLanguage` reads the user
  *locale* (`GetUserDefaultLCID`), which can differ from the Windows display
  language.

### Check that all languages expose the same keys

```bash
scripts/check-keys.sh            # compares every locale/*.lang against en.lang  
scripts/check-keys.sh locale fr  # use fr.lang as the reference instead  
```

It prints, per language, the **missing** and **extra** keys and exits non-zero  
on any mismatch — drop it into CI to keep translations honest.  
