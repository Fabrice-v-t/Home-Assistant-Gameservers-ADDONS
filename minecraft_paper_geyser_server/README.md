<p align="center">
  <img src="https://raw.githubusercontent.com/cyclemat/Home-Assistant-Gameservers-ADDONS/main/minecraft_paper_geyser_server/banner.png" alt="Minecraft Paper + Geyser Home Assistant Add-on" width="100%">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Home%20Assistant-00bcd4.svg">
  <img src="https://img.shields.io/badge/Type-Add--on-yellow.svg">
  <img src="https://img.shields.io/badge/AMD64-Tested-yellow.svg">
  <img src="https://img.shields.io/badge/ARM64-Untested-red.svg">
  <img src="https://img.shields.io/badge/Status-Beta-orange.svg">
</p>

---

# Minecraft Paper + Geyser (Java & Bedrock)

A Home Assistant add-on that runs a **Paper** Minecraft server together with
**Geyser** and **Floodgate**, so **Java Edition and Bedrock Edition players can play on the same server**.
Bedrock players (phone, console, Windows) do not need a Java account.

## Features

- Newest **stable** Paper build, resolved automatically through the official PaperMC downloads service (Fill v3)
- Paper download is verified by its SHA-256 checksum
- The Java version required by the selected Minecraft version is installed automatically (Temurin, checksum verified)
- Geyser and Floodgate are installed and refreshed on every start
- Optional extra plugins via direct `https` links
- EULA must be accepted explicitly (`accept_eula`)
- Clean shutdown: the world is saved when the add-on stops
- All data is stored in `/share/minecraft-paper`

## Ports

Only the ports that are actually needed are published. The host ports can be changed in the add-on network settings.

| Edition | Port | Protocol |
|---|---|---|
| Java | 25565 | TCP |
| Bedrock (Geyser) | 19132 | **TCP and UDP** |

Bedrock clients from version 26.60 on (planned for October 27th, 2026) only connect through
**NetherNet**. Geyser then needs a TCP port for the connection setup (signaling) in addition to the
UDP port for the game, both are 19132 by default. The add-on enables NetherNet for you and publishes
both. A UDP-only forward is not enough anymore.

The add-on does not use host networking and does not open anything else.
If you want to play from outside your home network, forward exactly these ports on your router
(19132 for TCP and UDP, 25565 for TCP). Do not forward other ports.
For an internet-facing server, enable the Minecraft whitelist (`white-list=true` in `server.properties`).

## Connecting

- **Java:** server address, default port 25565
- **Bedrock:** Servers, Add Server, server address, port 19132. Servers in a Home Assistant add-on are not
  announced on the LAN, so the server has to be added manually. When you join by IP address, Bedrock shows
  a one-time "trust on first use" prompt. Confirm it. It disappears if you serve the signaling over HTTPS,
  see the [Geyser documentation](https://geysermc.org/wiki/geyser/).

## Geyser configuration

On the first start the add-on creates a minimal `plugins/Geyser-Spigot/config.yml` with two settings:

- `java.auth-type: floodgate`, so Bedrock players can join without a Java account
- `bedrock.transport: nethernet`, see above

Geyser fills in all other options with its defaults. The file is never overwritten afterwards, so you can edit it
freely (for example `transport: both` with a separate `webrtc-port` while some players still use an older Bedrock
version). If Floodgate could not be downloaded, the file is not created and Geyser uses its own defaults.

## Configuration

| Option | Description |
|---|---|
| `accept_eula` | Must be `true` to start. By enabling it you agree to the [Minecraft EULA](https://aka.ms/MinecraftEULA) |
| `mc_version` | `latest` (newest version that has a stable Paper build) or a specific version, e.g. `1.21.11` |
| `allow_experimental` | Also accept beta/alpha Paper builds and pre-releases. PaperMC gives no support for them |
| `bedrock_support` | Install Geyser and Floodgate |
| `update_plugins` | Refresh Geyser and Floodgate on every start. If `false`, existing jars are kept |
| `plugin_urls` | Additional plugins as direct `https://...jar` links. Other schemes are ignored |
| `java_major` | Optional. Forces a Java version. By default it is read from Paper's version metadata |
| `xms_mb` / `xmx_mb` | Minimum / maximum RAM in MB (`xms_mb` must not exceed `xmx_mb`) |
| `whitelist_enabled` | Only whitelisted players can join |
| `whitelist` | Player names on the whitelist (Bedrock players with a leading dot) |
| `ops` | Player names with operator rights |
| `banned_players` | Player names on the ban list |

## Whitelist, ban list and operators

The three lists can be edited in the add-on configuration (**Whitelist**, **Banned players**, **Operators**).
Add one player name per entry. The whitelist is only enforced while **Enable the whitelist** is on.

On every start the add-on compares the lists with the server and sends the matching console commands
(`whitelist add`, `ban`, `op` and their counterparts) once the server is ready. The server looks up the UUIDs itself,
so Java names must belong to real Minecraft accounts.

- Only entries from the configuration are managed. Players you add in game stay.
- An entry that you delete from the configuration is removed from the server on the next start.
- Changes in the configuration take effect on the next start of the add-on.
- **Bedrock players** start with a dot, for example `.Steve` (Floodgate prefix, no spaces, use `_` instead).
  On the whitelist this uses Floodgate's `fwhitelist`. It looks the gamertag up in Geyser's cache, which does not know
  every player. If it does not find a player, enter the XUID instead of the gamertag (`.2535400000000000`).
  Operators and bans for Bedrock players only work after the player has joined once, because the server
  has to know the player first.

## Notes

- With `mc_version: latest` the server moves to the newest stable version on a restart.
  Back up your world first, downgrades can corrupt worlds. PaperMC itself advises against
  auto-updaters in production, so pin a version for a server you care about.
- Geyser can need a few days to support a brand-new Minecraft or Bedrock version. If Bedrock players
  cannot join after an update, pin `mc_version` to the previous version.
- Setting `bedrock_support` to `false` does not remove Geyser and Floodgate. Delete their jars from
  `/share/minecraft-paper/plugins` if you no longer want them.
- Server logs are written to `/share/minecraft-paper/logs/latest.log`.

## Architecture & Status

- **amd64**: startup with Java 25 and clean shutdown tested in Docker. A real Bedrock client has not been
  tested yet, so NetherNet behind the Home Assistant network bridge is still unverified
- **arm64**: should work (Java and Paper are architecture-aware), but not yet tested

Feedback and test reports are very welcome.
