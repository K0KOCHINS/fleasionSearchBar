# Fleasion Config Search Bar

Adds a **search bar** to the config enabler dropdown in [Fleasion](https://github.com/fleasion/Fleasion)'s Dashboard, so you can find your configs by typing instead of scrolling.

## What it does

- A search box sits at the top of the enabled-configs dropdown. The cursor is already in it when you open the menu, so just start typing.
- Matching ignores capital letters, and every word you type has to be in the name. For example, `blue sniper` finds `Sniper - Blue Ice`.
- **Enter** turns the first match on or off.
- **Esc** clears the search. Press it again to close the menu.
- The list shrinks to fit your results and shows **"No matching configs"** if nothing matches.
- The box starts empty every time you open the menu.

## Files in this repo

| File | What it is |
|---|---|
| `fleasion-config-search.patch` | **Use this one.** The full change: the search bar, its text in all 10 of Fleasion's languages, and tests. |
| `replacer_config.py` | Just the changed code file, for manual installs (see the bottom of this page). |

---

## How to install (Windows)

> **Why the extra steps?** The Fleasion `.exe` from their Releases page is already compiled, so it can't be edited. Instead, you download Fleasion's source code, add the search bar, and run it from there. Your configs are kept: the source version uses the same config folder as the `.exe`.

### Step 1: Install Git and uv (one time only)

Open **PowerShell**. Press the Windows key, type `powershell`, and hit Enter. Then run these two commands:

```powershell
winget install Git.Git
winget install astral-sh.uv
```

When both finish, **close PowerShell and open a new one**. The new window is needed so it can find the tools you just installed.

### Step 2: Download Fleasion's source code

```powershell
cd $HOME\Documents
git clone --config core.autocrlf=false https://github.com/fleasion/Fleasion.git
cd Fleasion
```

This creates a `Fleasion` folder inside your Documents.

> Keep the `--config core.autocrlf=false` part. Without it, Windows changes the line endings and the patch in the next step won't apply.

### Step 3: Add the search bar

Still in the same PowerShell window, run:

```powershell
Invoke-WebRequest https://raw.githubusercontent.com/K0KOCHINS/fleasionSearchBar/main/fleasion-config-search.patch -OutFile search.patch
git apply search.patch
```

If `git apply` prints nothing, it worked.

### Step 4: Run Fleasion

1. **Close your normal Fleasion first.** Right-click its tray icon and choose **Exit**. Two copies can't run at the same time.
2. Run:

   ```powershell
   uv run fleasion
   ```

The first launch takes a minute or two while it downloads what it needs. After that it starts quickly.

### Step 5: Use it

Open the **Dashboard** and click the enabled-configs dropdown. That's the button that says *No Configs Enabled*, a config name, or *X Configs Enabled*. The search bar is at the top.

---

## Starting it again later

Every time you want Fleasion with the search bar, open PowerShell and run:

```powershell
cd $HOME\Documents\Fleasion
uv run fleasion
```

### Optional: make your own .exe

If you'd rather double-click an app than type commands, build one:

```powershell
cd $HOME\Documents\Fleasion
uv run build
```

The new `.exe` appears in the `dist` folder inside `Documents\Fleasion`.

---

## Updating Fleasion without losing the search bar

Don't use the official installer or auto-updater; that would replace your version with one that has no search bar. Run these instead:

```powershell
cd $HOME\Documents\Fleasion
git stash
git pull
git stash pop
uv run fleasion
```

---

## Troubleshooting

**`git` or `uv` is "not recognized"**
You didn't open a new PowerShell after Step 1. Close it, open a new one, and try again.

**`git apply` says `patch does not apply` or `corrupt patch`**
Either Fleasion changed since this patch was made, or the line endings got converted. Delete the `Documents\Fleasion` folder and redo Step 2 exactly as written, including `--config core.autocrlf=false`. If it still fails, use the exact Fleasion version this patch was made for, then apply again:

```powershell
git checkout 7f4c6c1
git apply search.patch
```

**Fleasion won't start, or says it's already running**
The normal Fleasion is still open. Exit it from the tray icon, or end it in Task Manager.

**The search box shows `ui.gui.replacer_config.search_configs` instead of "Search configs..."**
You used the manual install below instead of the patch. Use the patch (Step 3) to get the proper text.

---

## Manual install (advanced)

Use this only if you can't get the patch to work. Do Steps 1–2, then copy `replacer_config.py` from this repo over:

```
Documents\Fleasion\src\fleasion\gui\replacer_config.py
```

Then run Step 4. The search bar works, but its placeholder text shows a raw label instead of "Search configs...", because the language files aren't updated this way.

---

Based on [Fleasion](https://github.com/fleasion/Fleasion). This is an unofficial add-on and isn't made by the Fleasion team.
