# omarchy-nextcloud

An [Omarchy](https://omarchy.org/) shell plugin that integrates the Nextcloud
desktop client into the Hyprland bar.

![status: bar widget showing Nextcloud sync state]

## What it does

- Shows a **cloud icon** in the bar that reflects your sync state in real time
  - Spinning while syncing
  - Dimmed / red on error
  - Green dot when up to date
- **Click** to open a panel with status details, the sync folder path, and
  quick-launch buttons
- **Right-click** to open the Nextcloud window directly
- **Suppresses the duplicate system-tray SNI entry** — no more redundant
  Nextcloud icon in the tray drawer

## Requirements

- [Omarchy](https://omarchy.org/) with Quickshell ≥ 0.3.1
- `nextcloud-client` package installed  
  (`omarchy pkg add nextcloud-client` or `pacman -S nextcloud-client`)

## Installation

### From git (recommended)

```bash
omarchy plugin add https://github.com/Maximilian-Maag/omarchy-nextcloud.git --enable
```

### Manual

```bash
git clone https://github.com/Maximilian-Maag/omarchy-nextcloud.git
bash omarchy-nextcloud/install.sh
```

### After installing

Start the Nextcloud daemon if it isn't running yet:

```bash
nextcloud --background &
```

If you haven't configured a server yet, click the bar icon (or run
`nextcloud`) to open the setup wizard.

## Suppress the SNI tray icon (optional)

The plugin automatically suppresses the Nextcloud entry from the system tray
drawer when the Nextcloud widget is present in the bar — exactly the same way
Omarchy handles Dropbox. No extra configuration needed.

## Uninstall

```bash
omarchy plugin remove maximilian-maag.nextcloud
```

## License

MIT
