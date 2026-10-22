# Plymouth Reference

A practical reference for Plymouth, the Linux boot splash system, and its scripting language.

Plymouth themes are built from small script-driven definitions that control animation, images, text, and boot lifecycle callbacks. Since the official material is fragmented, this project centralizes the useful references, helper scripts, and working examples in one place for quick experimentation and learning.

This repository is a compact theme lab and learning guide featuring:

- preview scripts that simulate the boot process, for fast iteration on Plymouth themes
- a set of working example themes (ready-to-use, easily adjustable templates) that demonstrate common patterns and techniques
- a collection of the best online references for Plymouth scripting and theme development

The focus is on the Plymouth scripting language itself: callbacks, sprite/image drawing, animation loops, and boot-state transitions.

## Table of contents

- [Prerequisites](#prerequisites)
- [Quick-start workflow](#quick-start-workflow)
- [Anatomy of a theme](#anatomy-of-a-theme)
- [Repository structure](#repository-structure)
- [Scripts in this repo](#scripts-in-this-repo)
- [Safer testing options](#safer-testing-options)
- [Manual theme installation](#manual-theme-installation)
- [Boot-delay and key-wait helpers](#boot-delay-and-key-wait-helpers)
- [Themes included](#themes-included)
- [Troubleshooting](#troubleshooting)
- [Useful external resources](#useful-external-resources)
- [Contributing](#contributing)
- [License](#license)

## Prerequisites

- `plymouth` and the script plugin (the package is often named `plymouth-plugin-script`, or is bundled with `plymouth`). Themes that declare `ModuleName=script` need it.
- `bash` and `sudo`. All scripts are bash; nothing else (such as fish) is required.
- `systemd`, for the boot-delay and key-wait helpers only.
- A virtual machine is recommended for testing (see [Safer testing options](#safer-testing-options)).

Package names vary by distribution; check yours.

## Quick-start workflow

Start with the theme closest to your goal, then adjust it iteratively while using a preview script to see your changes in action.

1. Pick a theme in `themes/` that resembles your goal (see [Themes included](#themes-included)).
2. Open the theme's `.plymouth` and `.script` files.
3. Run one of the preview scripts from the repository root to see it live.
4. Adjust the script to your needs and re-run the preview.
5. Use the documentation links below when you need the deeper reference.

## Anatomy of a theme

A theme is a directory containing a descriptor, a script, and assets.

`mytheme.plymouth`:

```ini
[Plymouth Theme]
Name=My Theme
Description=A minimal example
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/mytheme
ScriptFile=/usr/share/plymouth/themes/mytheme/mytheme.script
```

`mytheme.script`:

```text
Window.SetBackgroundTopColor(0, 0, 0);
Window.SetBackgroundBottomColor(0, 0, 0);

logo.image = Image("logo.png");
logo.sprite = Sprite(logo.image);
logo.sprite.SetX(Window.GetWidth() / 2 - logo.image.GetWidth() / 2);
logo.sprite.SetY(Window.GetHeight() / 2 - logo.image.GetHeight() / 2);
```

This draws a centered image on a black background; the `centeredimage` theme is the closest working example. See the resources below for callbacks such as `Plymouth.SetRefreshFunction` and `Plymouth.SetBootProgressFunction`.

The paths in the `.plymouth` file point at the installed location, so the theme's folder name must match the name used in `ImageDir` and `ScriptFile`.

## Repository structure

```text
.
├── README.md                     # This guide
├── preview.sh                    # Full Plymouth preview and boot-state simulation
├── testtheme.sh                  # Fast smoke test for a theme
├── lib/
│   └── common.sh                 # Helpers shared by the two scripts above
├── disable-boot-delay.sh         # See "Boot-delay and key-wait helpers"
├── enable-boot-delay.sh
├── disable-key-wait.sh
├── enable-key-wait.sh
└── themes/                       # Working example themes/templates
    ├── animframes/
    ├── centeredimage/
    ├── flappy/
    ├── full-featured/
    ├── fullscreenimage/
    ├── loading-animation/
    ├── pacman/
    ├── petthedog/
    └── randomsentence/
```

Each theme directory typically contains:

- a `.plymouth` descriptor file
- a `.script` file that implements the animation logic
- an `images/` folder or other assets used by the theme

## Scripts in this repo

Run `preview.sh` and `testtheme.sh` **as a normal user, from any directory**. They ask for `sudo` themselves, so do not prefix them with `sudo`. Both take a theme name from `themes/`; a missing or unknown name prints the list of available themes.

Both scripts leave your system as they found it: when they finish, or when you press Ctrl+C, they stop `plymouthd`, remove the installed copy of the theme, and restore your previous default theme. If a theme with the same name was already installed, it is backed up first and put back afterwards. Add `--keep` to leave the theme installed and selected instead.

### `preview.sh`

```bash
./preview.sh [--keep] <theme-name>
./preview.sh full-featured
```

Runs a deeper simulation of a Plymouth theme. It:

- copies the theme into `/usr/share/plymouth/themes/` and sets it as the default
- starts `plymouthd` in debug mode, logging to `/tmp/plymouth-preview.log`
- shows the splash and drives messages and progress steps (0-100%) through several boot stages
- shows a fake disk-encryption passphrase prompt for about two seconds, so the theme's password callback runs
- restores your previous theme and prints any errors or warnings found in the debug log

Use it for realistic testing when you want to observe a theme across a boot-like flow. It exercises all the functionality of a theme.

> **Notes**
>
> - Plymouth takes over the display while it runs, so you may get the best view from a text console or a VM rather than inside a running desktop session.
> - The test environment is not a real boot: some themes may not react to the simulated progress the way they would at boot.
> - The fake passphrase prompt is cancelled automatically and its output is discarded. Never type a real passphrase into it.
> - The temporary change to your default theme is undone automatically, but only if the script can exit normally. After a hard kill (`kill -9`) or a power loss, run `sudo plymouth quit` and restore your theme with `sudo plymouth-set-default-theme <previous-theme>`. The script prints the previous theme's name when it starts.

### `testtheme.sh`

```bash
./testtheme.sh [--keep] <theme-name> [seconds]
./testtheme.sh flappy 5
```

Shows the splash for a fixed number of seconds (default 5), then quits. It is the best choice when you only want to verify that a theme launches, without a full boot simulation. The same restore behavior and notes as `preview.sh` apply.

## Safer testing options

To avoid touching your host system's boot configuration:

- Test inside a virtual machine (QEMU/KVM, VirtualBox) and run the scripts there.
- Do it by hand: with the theme installed under `/usr/share/plymouth/themes/` and selected as default, run the daemon in the foreground and control the splash yourself:

  ```bash
  sudo plymouthd --debug --no-daemon &
  sudo plymouth show-splash
  # ...observe...
  sudo plymouth quit
  ```

## Manual theme installation

In general, a Plymouth theme is installed by copying the theme folder into `/usr/share/plymouth/themes/` and then selecting it and rebuilding the initramfs.

On many distributions, one command does both:

```bash
sudo plymouth-set-default-theme -R <theme-name>
```

Otherwise, set the theme and rebuild the initramfs separately. The rebuild command depends on your distribution:

| Distribution family | Command |
| --- | --- |
| Debian / Ubuntu | `sudo update-initramfs -u` |
| Arch Linux | `sudo mkinitcpio -P` |
| Fedora / RHEL / openSUSE | `sudo dracut -f` |

```bash
sudo plymouth-set-default-theme <theme-name>
sudo update-initramfs -u    # or the equivalent for your distribution
```

You may also have a graphical tool installed to set the theme.

## Boot-delay and key-wait helpers

These helper scripts install small `systemd` services that hold the boot on the splash, which is useful when you are working on an animation that would otherwise disappear within a second or two. They need root (`sudo`), and the preview scripts above do **not** need them.

| Script | What it does |
| --- | --- |
| `sudo ./enable-boot-delay.sh [seconds]` | Installs `plymouth-boot-delay.service`, which keeps the splash up for N seconds (1-600; asks if you omit it), counted from when Plymouth starts. |
| `sudo ./disable-boot-delay.sh` | Removes that service. |
| `sudo ./enable-key-wait.sh [timeout]` | Installs `plymouth-key-wait.service`, which holds boot until Enter is pressed on the main console (`tty1`), or until the timeout (default 60 s, max 3600 s) expires. |
| `sudo ./disable-key-wait.sh` | Removes that service. |

The two features use separate services, so they can be enabled independently. Both services run before the splash is closed and before the display manager starts, so they also delay the login screen. Both are stopped if a shutdown begins, so they cannot hold it up.

> **Warning**
>
> - These scripts create systemd units in `/etc/systemd/system/` and enable them for every boot until you disable them. **Always run the matching `disable-*` script when you are done testing.**
> - Key-wait reads from `tty1` only. On a headless server, a remote machine or a serial-only system nobody can press Enter, so boot will simply sit there until the timeout runs out. Do not enable it on such machines, and keep the timeout short.
> - Try these in a VM first; they have not been validated against a real boot on every distribution.
>
> **If a machine hangs on boot or a disable script fails:**
>
> 1. At the boot loader, add `systemd.mask=plymouth-key-wait.service` (or `systemd.mask=plymouth-boot-delay.service`) to the kernel command line for that one boot. This prevents the unit from running.
> 2. Once booted, run the matching `disable-*` script, or remove the unit by hand:
>
>    ```bash
>    sudo systemctl disable plymouth-key-wait.service
>    sudo rm /etc/systemd/system/plymouth-key-wait.service
>    sudo systemctl daemon-reload
>    ```
>
>    (Use `plymouth-boot-delay.service` for the delay.) From a rescue shell, deleting the unit file and the symlink in `/etc/systemd/system/plymouth-start.service.wants/` has the same effect.

## Themes included

The themes under `themes/` are example implementations that show different patterns and approaches.

| Theme | Focus | Preview |
| --- | --- | --- |
| `animframes` | GIF-like loop animation
| `centeredimage` | Centered image splash
| `flappy` | Active game-like motion
| `full-featured` | Advanced features for complete functionality; most published themes are simpler
| `fullscreenimage` | Full-screen background image
| `loading-animation` | A simple loading animation that progresses with boot state
| `pacman` | An interpolated progress bar, mixed with logic and animation
| `petthedog` | Minimal keyboard interaction (press space to pet the dog)
| `randomsentence` | A sentence is randomly picked from a list and displayed

## Troubleshooting

| Symptom | Things to check |
| --- | --- |
| `preview.sh` / `testtheme.sh` says a command is not found | Plymouth is not installed, or its tools are not in root's `PATH`. See [Prerequisites](#prerequisites). |
| Theme doesn't apply at boot | Did you rebuild the initramfs after selecting the theme? Is `splash` (and `quiet`) on the kernel command line? |
| Black screen instead of splash | Is the script plugin installed? Check the `ModuleName` and file paths in the `.plymouth` file. Read `/tmp/plymouth-preview.log` after a preview, or boot with `plymouth.debug` on the kernel command line and read the log it writes (usually `/var/log/plymouth-debug.log`). |
| Wrong resolution or scaling | Graphics drivers may load late; consider early KMS for your GPU. Use `Window.GetWidth()`/`GetHeight()` instead of hard-coded sizes. |
| Disk-encryption passphrase prompt missing | The theme must implement the password/question callbacks (see `full-featured`). |
| Images don't show | Check `ImageDir` and file names (paths are case-sensitive). |
| Splash stuck after a hard-killed preview | `sudo plymouth quit`, then restore your theme (see the notes under `preview.sh`). |
| Boot hangs on the splash | A key-wait service is probably enabled; see the recovery steps under [Boot-delay and key-wait helpers](#boot-delay-and-key-wait-helpers). |

## Useful external resources

- Schematic introduction: https://www.freedesktop.org/wiki/Software/Plymouth/Scripts/
  - Describes Plymouth's syntax, images, sprites, common callback functions, and math functions.
- ArchWiki: https://wiki.archlinux.org/title/Plymouth
  - Tools, configuration, tips and troubleshooting.
- Advanced: https://brej.org/blog/?cat=16
  - Plymouth step-by-step guide from scratch to a fully working theme, including direct, hashed and functional inheritance.
  - Provides a fully working "falling blocks" theme as an example.
- All callback functions (unofficial, community-maintained): https://github-wiki-see.page/m/Bha-Gu/theme/wiki/Plymouth-Functions
  - An incomplete list of callback functions, with examples and explanations.

Links may change over time; please open an issue if one is broken.

## Contributing

Help is welcome! We are currently looking for:

- improvements to the preview scripts
- better documentation of Plymouth's behavior and quirks (the engine itself, not the scripting language)
- testing and feedback on the example themes
- example themes for uncommon edge cases, like multi-monitor setups, high-DPI, or unusual aspect ratios
- any improvement to this document

To submit a theme:

1. Add it under `themes/<name>/` with a `.plymouth` file, a `.script` file, and its assets.
2. Start the script with a comment block describing what the theme demonstrates.
3. Add a row to the table above.
4. Check that `./testtheme.sh <name> 5` works, and say what you tested on.

## Copyright
Some used images are under Creative Commons licenses, in that case credits are shown.
Some other images were a gentle contribution from @la_scign_art origianlly commissioned by Pet the Dog.