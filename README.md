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
| `Install or Update Fleasion Search Bar.bat` | Double-click to add the search bar to your Fleasion, or update it. No PowerShell needed. |
| `fleasion-config-search.patch` | The actual change: the search bar, its text in all 10 of Fleasion's languages, and tests. |
| `replacer_config.py` | Just the changed code file, for manual installs. |
| `.github/workflows/build.yml` | Automatically builds the ready-to-use `.exe` on the Releases page. |

---

## How to install (Windows)

There are two ways to install it without typing any commands. **Option 1 is the easiest.**

### Option 1: Download the .exe (easiest)

1. Go to this repo's **[Releases page](https://github.com/K0KOCHINS/fleasionSearchBar/releases/latest)**.
2. Under **Assets**, download the file named `Fleasion-SearchBar-...-Windows.exe`.
3. **Exit your normal Fleasion first.** Right-click its tray icon and choose **Exit**.
4. Double-click the downloaded `.exe`. That's it.

Your configs carry over, because it uses the same config folder as normal Fleasion.

> **Windows says "Windows protected your PC"?** That shows up for any app that isn't code-signed. Click **More info**, then **Run anyway**.
>
> **Fleasion says "Update Available"?** Click **Cancel**. Downloading the official update gives you a version without the search bar. Get the newest version from this repo's Releases page instead.

### Option 2: One-click install or update

Use this to add the search bar to the Fleasion you already have, and to update it later.

1. Download [`Install or Update Fleasion Search Bar.bat`](https://github.com/K0KOCHINS/fleasionSearchBar/raw/main/Install%20or%20Update%20Fleasion%20Search%20Bar.bat). If your browser opens it as text instead, right-click the link and choose **Save link as**.
2. Double-click it. If Windows warns you, click **More info** then **Run anyway**.

It then does everything by itself:

- **Finds the Fleasion `.exe` you already have**, wherever you put it. If it can't find it, it asks you to pick it, or installs a fresh copy in `Documents\Fleasion` with a Desktop shortcut.
- **Replaces it with the newest Fleasion + Search Bar**, keeping the same file name, so your shortcuts and Run on Boot keep working.
- **Saves a backup** of your old Fleasion next to it, named `...backup.exe`.
- **Starts Fleasion.** You can close the black window; Fleasion keeps running.

If Fleasion is open, a popup asks you to exit it from the tray icon first.

**To update later, double-click the same file again.** If you already have the newest version, it just starts Fleasion.

> If this repo's Releases page has no `.exe` yet, the installer builds one on your PC instead. That takes 5-15 minutes the first time and installs Git and uv automatically.

### Where's the search bar?

Open Fleasion's **Dashboard** and click the enabled-configs dropdown. That's the button that says *No Configs Enabled*, a config name, or *X Configs Enabled*. The search bar is at the top.

---

## Manual install with PowerShell (advanced)

Only needed if both options above fail for you.

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

## Starting it again later (PowerShell install)

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

## Updating Fleasion without losing the search bar (PowerShell install)

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

**I want my old Fleasion back**
Delete your Fleasion `.exe` and rename the `...backup.exe` next to it back to the original name.

**The installer says `winget` is "not recognized"**
That only matters when it has to build on your PC. Your Windows is missing App Installer: get it from the Microsoft Store (search "App Installer"), or wait for the `.exe` to appear on the Releases page and run the installer again.

**The Releases page has no `.exe` yet**
The build takes about 10 minutes after the repo is updated. Check back shortly.

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

## Manual install with replacer_config.py (advanced)

Use this only if you can't get the patch to work. Do Steps 1–2, then copy `replacer_config.py` from this repo over:

```
Documents\Fleasion\src\fleasion\gui\replacer_config.py
```

Then run Step 4. The search bar works, but its placeholder text shows a raw label instead of "Search configs...", because the language files aren't updated this way.

---

## Credits

**Fleasion is made by the Fleasion team. Full credit for Fleasion itself goes to them.**

- **Fleasion:** https://github.com/fleasion/Fleasion
- **Discord:** https://discord.com/invite/pdtce585f6

From Fleasion's own [contributors list](https://github.com/fleasion/Fleasion/blob/main/CONTRIBUTORS.md):

- **@8ar__**, **@dis_spencer**, **@1_v** (Sky): code
- **@Blockce**, **@0100152000022000** (Sky 2), **@emk530**, **@yeha.** (Leah): logic and contributions
- Donators: for keeping the passion going

This repo only adds the config search bar on top of their work. It's an **unofficial add-on**, not made or endorsed by the Fleasion team. If something breaks in Fleasion itself, report it to them; if the search bar breaks, open an issue here.

## License

Fleasion is licensed under the [GNU GPL v3.0](https://github.com/fleasion/Fleasion/blob/main/LICENSE). This add-on modifies Fleasion's code, so it's released under the same **GPL v3.0** license. See [`LICENSE`](LICENSE).
