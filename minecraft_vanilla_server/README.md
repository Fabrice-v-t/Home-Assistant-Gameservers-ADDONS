<p align="center">
  <img src="https://raw.githubusercontent.com/cyclemat/Home-Assistant-Gameservers-ADDONS/main/minecraft_vanilla_server/banner.png" alt="Minecraft Vanilla Dedicated Server Home Assistant Add-on" width="100%">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Home%20Assistant-00bcd4.svg">
  <img src="https://img.shields.io/badge/Type-Add--on-yellow.svg">
  <img src="https://img.shields.io/badge/AMD64-Tested-yellow.svg">
  <img src="https://img.shields.io/badge/ARM64-Untested-red.svg">
  <img src="https://img.shields.io/badge/Status-Beta-orange.svg">
</p>

---

<h1>Minecraft Vanilla Dedicated Server</h1>

This Home Assistant Add-on allows you to run a **Minecraft Vanilla Dedicated Server**
directly on **Home Assistant OS**, fully managed by the Supervisor.

It is designed to be:

- simple
- headless
- reproducible
- configurable via the Home Assistant UI
- suitable for LAN and private servers

---

## ✨ Features

- Automatic **Java installation** (Temurin). The Java version is read from Mojang's
  version metadata, so every Minecraft version gets the runtime it needs
- Automatic **Minecraft server download**, verified by its SHA-1 checksum
- **EULA must be accepted explicitly** (`accept_eula`)
- Fixed **container port 25565** (host port configurable via HA UI)
- Configurable **RAM settings** (`Xms` / `Xmx`)
- Persistent server data stored in `/share`
- Live Minecraft server output in the Home Assistant add-on log
- **Clean shutdown**: the world is saved when the add-on stops
- Runs fully inside **Home Assistant OS**
- No external server or launcher required

---

## 📂 Server Files Location

All server files are stored persistently in:

```
/share/minecraft-vanilla/
├── server.jar
├── world/
├── logs/
└── .jre/
```

You can freely edit:
- `server.properties`
- worlds
- logs
- and other vanilla configuration files

The server log is written to `/share/minecraft-vanilla/logs/latest.log`.

---

## 🔧 Installation

1. Open **Home Assistant**
2. Go to **Settings → Add-ons → Add-on Store**
3. Add this repository if not already added:

https://github.com/cyclemat/Home-Assistant-Gameservers-ADDONS

4. Install **Minecraft Vanilla Dedicated Server**
5. Open the configuration and enable **`accept_eula`**
6. Start the server

---

## ⚙️ Configuration Options

| Option | Description |
|-----|------------|
| `accept_eula` | Must be `true` to start. By enabling it you agree to the [Minecraft EULA](https://aka.ms/MinecraftEULA) |
| `mc_version` | `latest` or a specific Minecraft version (e.g. `1.21.1`) |
| `server_jar_url` | Optional custom server JAR URL (`https` only). Overrides `mc_version` and is not checksum verified |
| `java_major` | Optional. Forces a Java version. By default it is read from Mojang's version metadata |
| `xms_mb` | Minimum RAM (MB), must not exceed `xmx_mb` |
| `xmx_mb` | Maximum RAM (MB) |

> ℹ️ The Minecraft server always runs on port **25565 inside the container**.  
> The external port can be changed in the Home Assistant add-on network settings.

---

## ⬆️ Updating from 0.0.2

Version 0.0.3 contains two changes you should know about:

- **The EULA is no longer accepted automatically.** After updating, open the add-on
  configuration and enable `accept_eula` once. Until then the add-on stops with a
  clear message in the log.
- **The Java version now follows the Minecraft version** instead of being fixed to
  Java 21. This fixes the `UnsupportedClassVersionError` on newer Minecraft
  releases (class file version 69 needs Java 25). Old Java runtimes in
  `.jre/` are removed automatically.

With `mc_version: latest` the server moves to the newest release on a restart.
Back up your world first, downgrades can corrupt worlds. Pin `mc_version`
for a server you care about.

---

## 🧪 Architecture & Status

- **amd64**: tested and working
- **arm64**: should work, but **not yet fully tested**

ARM64 support is implemented (Java + server are architecture-aware),
but real-world feedback is highly appreciated.

👉 If you are running this add-on on **ARM64 hardware**
(e.g. Home Assistant Green, Raspberry Pi 64-bit),
please consider testing it and sharing your results.

---

## ❤️ Feedback & Support

This add-on is developed and maintained in my free time.

If you try it out:
- feedback
- bug reports
- improvement suggestions
- ARM64 test results

are very welcome and highly appreciated.

---

> **“Every block placed is a step into your own story.”**  
> *Inspired by Minecraft*
