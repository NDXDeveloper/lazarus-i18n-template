# Adding a language — step by step

This tutorial adds **Portuguese (`pt`)** to the template — a language that is not  
bundled yet. Substitute any code you like: ISO 639-1 (two letters, e.g. `pt`,  
`nl`) or ISO 639-3 (e.g. `ary`, `arq`). No code changes and no recompilation of
the localization engine are needed — `.lang` files are read at runtime.

---

## 1. Copy the reference file

English (`en.lang`) is the reference: it always contains every key. Copy it to  
the new code:  

```bash
cp locale/en.lang locale/pt.lang
```

> Keep the file name equal to the language code: `pt.lang`, `nl.lang`, `ja.lang`…

## 2. Edit the `[Language]` header

Open `locale/pt.lang` and update **only** the header values (leave the keys):

```ini
[Language]
Name=Portuguese - Português  
Code=pt  
Author=Your Name  
```

* `Name` is what users see in the **Options ▸ Language** menu and the Options
  drop-down. The convention is **`English name - Endonym`** — e.g.
  `Portuguese - Português`, `German - Deutsch`, `Japanese - 日本語`. (The reference
  file `en.lang` is the exception: it simply uses `English`.)
* `Code` must match the file name (`pt`).

## 3. Translate the values

Go through every section and translate the **values**, while keeping:

* the **keys** unchanged (they stay in English);
* the **`&`** accelerators (pick a sensible letter for the language);
* the **format placeholders** `%s` `%d` `%f` `%%` and **their order**.

```ini
[Menu]
File=&Ficheiro  
FileOpen=&Abrir ficheiro...  
FileExit=&Sair  

[Dialog]
Welcome=Bem-vindo, %s!

[Message]
ProgressFormat=Progresso: %d%%
```

Save the file as **UTF-8 (without BOM)** so accented characters render correctly  
on Windows and Linux.  

## 4. Check the keys are in sync

```bash
scripts/check-keys.sh
```

Every file must expose the same keys as `en.lang`; your new file appears in the  
list (one line per language):  

```
Reference: en.lang (63 keys)

OK   ar.lang — keys match en.lang
…
OK   pt.lang — keys match en.lang
…
All language files are in sync.
```

If it reports **Missing** keys, copy them from `en.lang` and translate them; if it  
reports **Extra** keys, remove them.  

## 5. Test it

The new language is picked up automatically — there is nothing to register in  
code.  

* **From the UI:** run the app, open **Options ▸ Language** (or the Options
  dialog), and choose *Portuguese - Português*. The whole interface updates
  instantly.
* **Via auto-detection:** start the app with the matching locale and it opens in
  Portuguese straight away:

  ```bash
  # Linux/macOS
  LANG=pt_PT.UTF-8 ./lazarus_i18n_template
  ```

> Auto-detection only applies when **no language has been saved yet**. If you have  
> already picked a language in **Options**, that saved choice wins. Clear it by  
> deleting the config file  
> (`~/.config/lazarus-i18n-template/config.ini`, or on Windows  
> `%APPDATA%\lazarus-i18n-template\config.ini`) — see  
> [`localization.md`](localization.md#remembering-the-choice-uconfig).

> Make sure `locale/pt.lang` sits next to the executable (it already does in this  
> template, which builds into the project root). See the README for other output  
> layouts.

---

## Checklist

- [ ] `locale/<code>.lang` created from `en.lang`
- [ ] `[Language]` header updated (`Name`, `Code`, `Author`)
- [ ] every value translated; keys, `&` and `%…` placeholders preserved
- [ ] file saved as UTF-8 (no BOM)
- [ ] `scripts/check-keys.sh` reports the file in sync
- [ ] language appears in **Options ▸ Language** and switches live
