# Meu Drive

_[Português](README.md)_

**Meu Drive** is an Android app that works purely as a **friendly interface** for
Syncthing: it does not implement any synchronization of its own and reinvents
nothing — **all the credit for the engine goes to Syncthing**
(https://github.com/syncthing/syncthing). The goal is to hide Syncthing's
technical concepts (device, folder ID, discovery, relay) and present the folders
with **friendly names**, clear sync states and an ordinary file browser, so that
anyone can use it as an everyday **file manager** — without ever needing to know
there is a sync engine behind it.

## What it does

- Shows the synced folders with friendly names, item count, size and state
  (synced, syncing, paused, error).
- Lets you browse files like a regular explorer: list or grid, photo thumbnails,
  a full-screen viewer, sorting by name/date/size (per-folder preferences) and
  opening files in other apps.
- Also browses files on the phone that are **not** synced.
- Manages folders and computers (add, edit, share, remove), with pairing by
  **Device ID** or **QR code**.
- Wakes and keeps the sync running on its own, with a discreet notification.
- Checks for updates and installs new versions from inside the app.

## Screenshots

<p align="center">
  <img src="docs/capturas/01-inicio.png" width="300" alt="Home screen">
  <img src="docs/capturas/02-configuracoes.png" width="300" alt="Settings screen">
</p>

## How it works

Syncthing is **embedded** in the app (the official engine binary is packaged
along with it) and runs in a foreground service. There is no cloud, account,
sign-up or telemetry: data only travels directly between your devices.

## Installing Syncthing on your computer

On your computer, install the **official Syncthing** for your system:
https://syncthing.net/downloads/ — the official quick start guide is at
https://docs.syncthing.net/intro/getting-started.html.

It only takes a few steps: install it, open it (it generates the configuration
and opens the web interface), add the folder you want to share and pair it with
your phone using the **Device ID**. On Windows, if you want a tray icon you can
use **SyncTrayzor** (https://github.com/canton7/SyncTrayzor). On the phone you
don't need to install anything besides Meu Drive itself, which already ships the
same engine.

## Pairing your phone with your computer

1. In Meu Drive: **Manage → Computers → "My ID on this device"** (shows the
   Device ID and a QR code).
2. In the computer's Syncthing: **Add Remote Device** and enter that ID (or scan
   the QR code).
3. Share the same folder on both sides (in Meu Drive: **Manage → Folders → edit →
   check the computer**).
4. Done: anything that shows up in the folder will be synced.

If the devices cannot find each other, see Syncthing's firewall page:
https://docs.syncthing.net/users/firewall.html.

## Privacy

No telemetry, no analytics, no servers of our own. Synchronization is
peer-to-peer between your devices (when needed, Syncthing may use its own public
discovery and relay services).

## License

This project is distributed under the **GNU General Public License v3.0** (see
the [`LICENSE`](LICENSE) file).

Third-party credits and licenses:

- **Syncthing** — synchronization engine, licensed under **MPL-2.0**
  (https://github.com/syncthing/syncthing). The engine binary is redistributed
  unmodified.
- **Syncthing-Fork / syncthing-android** (MPL-2.0) — reference for packaging the
  engine on Android and the source of the binary used by the update script.

## Notice

This is an **unofficial** project and is **not affiliated** with the Syncthing
project. The "Syncthing" name and trademark belong to its authors. Meu Drive
merely provides an alternative interface for the engine.
