# Plymouth Reference

This repository is a practical reference for Plymouth, the Linux boot splash system and its scripting language.

Plymouth themes are built from small script-driven definitions that control animation, images, text, and boot lifecycle callbacks. The problem is that the official material is fragmented and the scripting language is easy to learn in pieces but harder to learn as a whole. This project centralizes the useful references, helper scripts, and working examples in one place for quick experimentation.

This repo is a compact theme lab and learning guide featuring:

- support for fast iteration and experimentation with Plymouth themes through preview scripts that simulate the boot process
- a set of working example themes (ready-to-use, easily adjustable templates) that demonstrate common patterns and techniques
- collection of the best online references for Plymouth scripting and theme development

The focus is on the Plymouth scripting language itself: callbacks, sprite/image drawing, animation loops, and boot-state transitions.

## Walk-in-and-use workflow

I recommend starting with a theme that is closest to your goal, and then iteratively adjusting it while using the preview script to see your changes in action.

1. Pick a theme in `themes/` that resembles your goal, descriptions of their behavior is described in the files.
2. Open the theme's `.plymouth` and `.script` files.
3. Run the preview script to see it live.
4. Adjust the script to your needs and re-run the preview script to see changes.
5. Use the documentation links below when you need the deeper reference.

## Repository structure

```text
.
├── README.md                     # This guide
├── preview.sh                    # Full Plymouth preview and boot-state simulation
├── testtheme.sh                  # Fast smoke test for a theme
├── disable-boot-delay.sh         # see below (Boot-delay and key-wait helpers)
├── enable-boot-delay.sh          # see below
├── disable-key-wait.sh           # see below
├── enable-key-wait.sh            # see below
├── themes/                       # Working example themes/templates
│   ├── animframes/
│   ├── centeredimage/
│   ├── flappy/
│   ├── full-featured/
│   ├── fullscreenimage/
│   ├── loading-animation/
│   ├── pacman/
│   ├── petthedog/
│   └── randomsentence/
└── ...
```

Each theme directory typically contains:

- a `.plymouth` descriptor file
- a `.script` file that implements the animation logic
- an `images/` folder or other assets used by the theme

## Scripts in this repo

### `preview.sh`

Runs a deeper simulation of a Plymouth theme.

It:

- copies a theme into `/usr/share/plymouth/themes/`
- sets it as the default theme
- starts `plymouthd` in debug mode
- shows a splash and drives progress steps through several boot stages
- prints a debug summary for troubleshooting

Use it for realistic testing when you want to observe a theme across a boot-like flow. This tests all functionalities of a theme.
Note that this may change your system's real theme, the copy is not removed after the preview, and it may leave `plymouthd` running in the background. You can stop it with `sudo plymouth quit`.
Also note that the testing environment is not fully functional, so some themes may not work as expected. For example, the script tries to simulate boot progression, but the environment actively ignores it.

Example:

```bash
./preview.sh full-featured
```

### `testtheme.sh`

Runs a fast simple preview for a fixed number of seconds.

It is the best choice when you only want to verify that a theme launches without a full boot simulation.

Example:

```bash
./testtheme.sh flappy 5
```

### Boot-delay and key-wait helpers

These helper scripts modify `systemd` services to control whether the boot animation stays visible for a chosen delay or waits for Enter before continuing.

- `enable-boot-delay.sh`: adds a delay service to keep the Plymouth animation on screen for a chosen time.
- `disable-boot-delay.sh`: removes the delay service.
- `enable-key-wait.sh`: blocks boot until Enter is pressed.
- `disable-key-wait.sh`: removes that wait condition.

## Themes included

The themes under `themes/` are example implementations that show different patterns and approaches:

| Theme | Focus |
| --- | --- |
| `animframes` | Gif-like animation |
| `centeredimage` | Centered image splash |
| `flappy` | Active game-like motion |
| `full-featured` | Shows off advanced features for complete functionality, most of the real themes don't have this level of complexity |
| `fullscreenimage` | Full-screen background image |
| `loading-animation` | A simple loading animation that shows progress |
| `pacman` | An interpolated progress bar, mixed with logic and animation |
| `petthedog` | Test out minimal keyboard interaction |
| `randomsentence` | Test out randomness |

## Useful external resources

- Schematic introduction: https://www.freedesktop.org/wiki/Software/Plymouth/Scripts/
- - Describes Plymouth's syntax, Images, Sprites, common callback functions, and math functions.
- ArchWiki : https://wiki.archlinux.org/title/Plymouth
- - Tools, configuration, tips and troubleshooting.
- Advanced: https://brej.org/blog/?cat=16
- - Plymouth step-by-step guide from scratch to a fully working theme, includes direct, hashed and functional inheritance.
- - Provides a fully working "falling blocks" theme as an example.
- All callback functions: https://github-wiki-see.page/m/Bha-Gu/theme/wiki/Plymouth-Functions
- - An "incomplete" list of all callback functions, with examples and explanations.

## Contributing

Help is welcome!
We are currently looking for:
- improvements to the preview scripts
- a better documentation of Plymouth's behavior and quirks (not the scripting language, but the engine itself)
- testing and feedback on the example themes
- example themes for uncommon edges cases, like multi-monitor setups, high-DPI, or unusual aspect ratios