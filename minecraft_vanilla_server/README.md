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

- Automatic **Java installation** (Temurin, checksum verified). The Java version is read from Mojang's
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
| `whitelist_enabled` | Only whitelisted players can join |
| `whitelist` | Player names on the whitelist |
| `ops` | Player names with operator rights |
| `banned_players` | Player names on the ban list |
| `performance_profile` | `custom`, `low`, `balanced` or `high` (view and simulation distance, max players) |
| `cpu_priority` | `normal`, `low` or `lowest` |
| `cpu_cores` | Number of CPU cores, `0` = all |
| `memory_guard` | Limit `xmx_mb` so RAM stays free for the system |
| `fixed_heap` | `xms_mb` = `xmx_mb`, claim the memory at startup |

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

## 👥 Whitelist, ban list and operators

The three lists can be edited in the add-on configuration (**Whitelist**, **Banned players**, **Operators**).
Add one player name per entry. The whitelist is only enforced while **Enable the whitelist** is on.

On every start the add-on compares the lists with the server and sends the matching console commands
(`whitelist add`, `ban`, `op` and their counterparts) once the server is ready. The server looks up the UUIDs itself,
so the names must belong to real Minecraft accounts.

- Only entries from the configuration are managed. Players you add in game stay.
- An entry that you delete from the configuration is removed from the server on the next start.
- Changes in the configuration take effect on the next start of the add-on.

---

## ⚙️ Performance and resource limits

Home Assistant cannot set CPU or memory limits per add-on, so the add-on applies them itself:

| Option | What it does |
|---|---|
| `performance_profile` | `custom` leaves `server.properties` alone. `low` (view distance 6, simulation distance 4, 10 players), `balanced` (8, 6, 20) and `high` (12, 8, 40) set `view-distance`, `simulation-distance` and `max-players` on every start. The simulation distance has the biggest effect on CPU load. |
| `cpu_priority` | `normal`, `low` (nice 10) or `lowest` (nice 19). With a lower priority the server gives way to Home Assistant when the CPU is busy. |
| `cpu_cores` | Number of CPU cores the server may use, `0` means all. The server runs on the last cores, so the first ones stay free for the system and Home Assistant. Java adjusts its GC and JIT threads to the core count. |
| `memory_guard` | Limits `xmx_mb` automatically so that at least a quarter of the system RAM (and at least 1536 MB) stays free. A container memory limit is taken into account. Without it Linux ends the add-on first when memory runs out. |
| `fixed_heap` | Sets `xms_mb` equal to `xmx_mb` and claims the memory at startup. This avoids heap resizing while running, as Paper recommends. Starting takes a little longer. |

The add-on always starts Java with the G1 garbage collector. Without it Java silently falls back to the slow
SerialGC on machines with fewer than 2 CPUs or less than 1.75 GB RAM.

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
