# Dgn Tracker

> **Dungeon, Raid, Delve & Torghast entrance tracker for World of Warcraft — all expansions from Vanilla to Midnight.**

![Interface](medias/DgnTracker.png)

---

## Overview

**Dgn Tracker** is a World of Warcraft addon that gives you a clear, sortable reference window for every instanced content entrance in the game. Whether you're looking for an old dungeon you've never visited, planning a raid transmog run, or trying to find a Delve tucked away in The War Within, Dgn Tracker has you covered.

For each instance, the addon displays:
- The **continent**, **zone**, and **sub-zone** where the entrance is located
- The **access path** and any **tips** for reaching it
- The **instance type** (Dungeon, Raid, Delve, Torghast/Tourment)
- The **expansion** it belongs to

All data is organized by expansion, from **Vanilla (1.0)** to **Midnight (12.0)**, with a clean tabbed interface that lets you jump directly to the content you need.

---

## Features

- 📋 **Complete instance database** — every dungeon, raid, Delve (Gouffre), and Torghast wing across all 12 expansions
- 🗂️ **Expansion tabs** — two rows of quick-access tabs (Midnight → Vanilla) with colour-coded labels per expansion
- 🔖 **Instance type tabs** — switch between Dungeons, Raids, Delves, and Torghast within each expansion
- 📖 **Accordion layout** — expand/collapse individual instances to read their entrance details and tips
- 🗺️ **Map pins** — optional map markers for instance entrances (requires **TomTom**)
- 🧭 **Minimap button** — drag-repositionable minimap icon for instant access; also accessible from the addon compartment button
- 💾 **Persistent settings** — your last selected expansion, tab, window position, and open/closed state are saved between sessions
- 🌐 **Bilingual UI** — interface labels in both English and French (`frFR`)

### Expansions covered

| Abbreviation | Expansion | Patch |
|---|---|---|
| MID | Midnight | 12.0 |
| TWW | The War Within | 11.0 |
| DF | Dragonflight | 10.0 |
| SL | Shadowlands | 9.0 |
| BfA | Battle for Azeroth | 8.0 |
| LEG | Legion | 7.0 |
| WoD | Warlords of Draenor | 6.0 |
| MoP | Mists of Pandaria | 5.0 |
| CATA | Cataclysm | 4.0 |
| WotLK | Wrath of the Lich King | 3.0 |
| TBC | The Burning Crusade | 2.0 |
| VAN | Vanilla | 1.0 |

---

## Slash Commands

| Command | Description |
|---|---|
| `/tdg` | Open / close the Dgn Tracker window |
| `/tibidgn` | Alias — also opens / closes the window |
| `/tdg map on` | Enable map pins (requires TomTom) |
| `/tdg map off` | Disable map pins |
| `/tdg reset` | Collapse all expanded instance entries |
| `/tdg help` | Display available commands in chat |

---

## Installation

### Manual

1. Download the latest release and unzip it.
2. Copy the `DgnTracker` folder into your WoW addons directory:
   ```
   World of Warcraft\_retail_\Interface\AddOns\DgnTracker
   ```
3. Launch (or reload) WoW and enable **Dgn Tracker** in the AddOns list on the character selection screen.
4. Type `/tdg` in-game to open the tracker.

### CurseForge / Wago Addons

Search for **Dgn Tracker** and install via your preferred addon manager (CurseForge App, Wago App, etc.).

---

## Optional Dependencies

| Addon | Purpose |
|---|---|
| [TomTom](https://www.curseforge.com/wow/addons/tomtom) | Adds waypoint arrows and map pins for instance entrances |

TomTom is not required to use Dgn Tracker. Map pin features are simply unavailable if TomTom is not installed.

---

## Compatibility

| Field | Value |
|---|---|
| **Interface** | 120007 (Retail), 120005 |
| **Version** | 3.0 |
| **Game version** | Retail (The War Within / Midnight PTR) |

---

## Author

**Tibiscui** — Kirin Tor (EU)

---

## License

This project is licensed under the [MIT License](LICENSE).

---

## Français

**Dgn Tracker** est un addon World of Warcraft qui répertorie toutes les entrées d'instances du jeu : Donjons, Raids, Gouffres (Delves) et Torghast, de Vanilla à Midnight. Pour chaque instance, il indique le continent, la zone, le sous-zone, le chemin d'accès et des conseils pour s'y rendre. L'interface est organisée par extension avec des onglets colorés et un affichage en accordéon. Les marqueurs cartographiques sont disponibles via TomTom.

**Commandes** : `/tdg` pour ouvrir/fermer la fenêtre • `/tdg help` pour l'aide complète.
