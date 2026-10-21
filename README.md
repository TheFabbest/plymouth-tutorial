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
These are the packages and conditions needed to run the preview scripts and test Plymouth themes:

- `plymouth` and the script plugin (the package is often named `plymouth-plugin-script`, or is bundled with `plymouth`). Themes that declare `ModuleName=script` need it.
- Root privileges (`sudo`) for the scripts that install themes or edit systemd units.
- A Linux system with `systemd`. A virtual machine is recommended for testing (see [Safer testing options](#safer-testing-options)).

Package names vary by distribution; check yours.

## Quick-start workflow

Start with the theme closest to your goal, then adjust it iteratively while using a preview script to see your changes in action.

1. Pick a theme in `themes/` that resembles your goal. Each theme's behavior is described in comments at the top of its files.
2. Open the theme's `.plymouth` and `.script` files.
3. Run one of the preview scripts to see it live.
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

This draws a centered image on a black background. See the `centeredimage` theme for a working version, and the resources below for callbacks such as `Plymouth.SetRefreshFunction` and `Plymouth.SetBootProgressFunction`.

## Repository structure

```text
.
├── README.md                     # This guide
├── preview.sh                    # Full Plymouth preview and boot-state simulation
├── testtheme.sh                  # Fast smoke test for a theme
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

### `preview.sh`

Runs a deeper simulation of a Plymouth theme. It:

- copies a theme into `/usr/share/plymouth/themes/`
- sets it as the default theme
- starts `plymouthd` in debug mode
- shows a splash and drives progress steps through several boot stages
- prints a debug summary for troubleshooting

Use it for realistic testing when you want to observe a theme across a boot-like flow. It exercises all functionality of a theme.

> **Warning**
>
> - It **changes your system's default Plymouth theme**.
> - The copied theme is **not removed** afterwards.
> - It may **leave `plymouthd` running**; you can stop it with `sudo plymouth quit`.
> - The test environment is not fully functional: the script simulates boot progression, but the environment may ignore it, so some themes may not behave as they would at real boot.
>
> Before running it, note your current theme so you can restore it:
>
> ```bash
> plymouth-set-default-theme          # prints the current theme
> # ...run the preview...
> sudo plymouth quit
> sudo plymouth-set-default-theme <previous-theme>
> ```

It writes to `/usr/share`, so it needs root. Run it with `sudo` unless the script elevates itself.

```bash
sudo ./preview.sh full-featured
```

### `testtheme.sh`

Runs a fast, simple preview for a fixed number of seconds. It is the best choice when you only want to verify that a theme launches, without a full boot simulation.

```bash
sudo ./testtheme.sh flappy 5
```

If the splash stays on screen afterwards, stop it with `sudo plymouth quit`.

## Safer testing options

To avoid touching your host system's boot configuration:

- Test inside a virtual machine (QEMU/KVM, VirtualBox) and run the preview scripts there.
- Run the daemon in the foreground with debug output, then show and quit the splash by hand:

  ```bash
  sudo plymouthd --debug --no-daemon &
  sudo plymouth --show-splash
  # ...observe...
  sudo plymouth quit
  ```

  This still needs the theme to be installed under `/usr/share/plymouth/themes/` and selected as default.

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

These helper scripts modify `systemd` services to control whether the boot animation stays visible for a chosen delay or waits for Enter before continuing.

- `enable-boot-delay.sh`: adds a delay service to keep the Plymouth animation on screen for a chosen time.
- `disable-boot-delay.sh`: removes the delay service.
- `enable-key-wait.sh`: blocks boot until Enter is pressed.
- `disable-key-wait.sh`: removes that wait condition.

> **Warning**
>
> - These scripts create or edit `systemd` units and need root.
> - **Do not enable key-wait on headless servers, remote machines, or unattended VMs.** Boot will stall until someone presses Enter at the console.
> - Always run the matching `disable-*` script when you are finished testing.
> - If a machine hangs or the disable script fails, boot into recovery/rescue mode (or edit the kernel command line) and remove the added unit manually, for example from `/etc/systemd/system/`, then run `systemctl daemon-reload`. Check the script source for the exact unit name.

## Themes included

The themes under `themes/` are example implementations that show different patterns and approaches.

| Theme | Focus | Preview |
| --- | --- | --- |
| `animframes` | GIF-like animation | _screenshot/GIF_ |
| `centeredimage` | Centered image splash | _screenshot/GIF_ |
| `flappy` | Active game-like motion | _screenshot/GIF_ |
| `full-featured` | Advanced features for complete functionality; most published themes are simpler | _screenshot/GIF_ |
| `fullscreenimage` | Full-screen background image | _screenshot/GIF_ |
| `loading-animation` | A simple loading animation that shows progress | _screenshot/GIF_ |
| `pacman` | An interpolated progress bar, mixed with logic and animation | _screenshot/GIF_ |
| `petthedog` | Minimal keyboard interaction | _screenshot/GIF_ |
| `randomsentence` | Randomness | _screenshot/GIF_ |

## Troubleshooting

| Symptom | Things to check |
| --- | --- |
| Theme doesn't apply at boot | Did you rebuild the initramfs after selecting the theme? Is `splash` (and `quiet`) on the kernel command line? |
| Black screen instead of splash | Is the script plugin installed? Check the `ModuleName` and file paths in the `.plymouth` file. Run `plymouthd --debug` and read the log (commonly `/var/log/plymouth-debug.log`). |
| Wrong resolution or scaling | Graphics drivers may load late; consider early KMS for your GPU. Use `Window.GetWidth()`/`GetHeight()` instead of hard-coded sizes. |
| Disk-encryption passphrase prompt missing | The theme must implement the password/question callbacks (see `full-featured`). |
| Images don't show | Check `ImageDir` and file names (paths are case-sensitive). |
| Splash stuck after preview | `sudo plymouth quit` |

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

To submit a theme:

1. Add it under `themes/<name>/` with a `.plymouth` file, a `.script` file, and its assets.
2. Start the script with a comment block describing what the theme demonstrates.
3. Add a row to the table above.
4. Check that `./testtheme.sh` works, and say what you tested on.

## Related projects
A VSCode extension for Plymouth syntax highlighting is available in the Visual Studio Marketplace, its source code is at https://github.com/TheFabbest/language-support-for-plymouth.