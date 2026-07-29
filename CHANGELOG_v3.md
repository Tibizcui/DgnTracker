# DgnTracker 3.0

## English

**DgnTracker 3.0 is a big maintenance and feature update. The slash command is now `/dg` (shorter), and waypoints finally work.**

### New features
- **Waypoints that actually work.** Right-click any instance to drop a route marker. If TomTom is installed you get the full floating arrow, otherwise DgnTracker falls back to Blizzard's native map waypoint. No extra addon required.
- **Auto-waypoint mode.** Type `/dg map on` to automatically set a waypoint whenever you expand an instance. `/dg map off` turns it back off. Your choice is saved between sessions.
- **Search box.** A filter field in the top-right corner lets you find any instance in the current list by name as you type.
- **Jump to an expansion by command.** `/dg tww`, `/dg df`, `/dg sl`, `/dg bfa`, `/dg van` and so on take you straight to that expansion.
- **Expand everything at once.** `/dg expand` opens every entry of the active expansion; `/dg reset` collapses them all.

### Bug fixes
- Fixed the version number, which still showed 1.3 in-game while the addon was really 3.0.
- Fixed the advertised map commands that did nothing. `/dg map on` / `/dg map off` are now real and wired to the waypoint system.
- Cleaned up duplicated data keys in the Dragonflight and Shadowlands databases.
- Added the missing colour for the Vanilla tab, which was showing in grey.
- Hardened the minimap button against the deprecated `math.atan2` on recent clients.
- Pressing Escape now closes only the DgnTracker window instead of leaking to other keybinds.

### Under the hood
- The instance list now recycles its widgets instead of rebuilding them on every refresh. This removes a slow memory buildup during long sessions and makes tab switching snappier.

### Command reminder
The command changed from `/tdg` to `/dg`. The `/tibidgn` alias still works. Type `/dg help` for the full list.

---

## Français

**DgnTracker 3.0 est une grosse mise à jour de fond. La commande devient `/dg` (plus courte), et les points de route (waypoints) fonctionnent enfin.**

### Nouveautés
- **Des waypoints qui marchent vraiment.** Clic droit sur une instance pour poser un point de route. Avec TomTom installé, vous avez la flèche directionnelle complète, sinon DgnTracker bascule automatiquement sur le marqueur de carte natif de Blizzard. Aucun addon supplémentaire obligatoire.
- **Mode waypoint automatique.** Tapez `/dg map on` pour poser un waypoint dès que vous dépliez une instance. `/dg map off` le désactive. Le choix est mémorisé entre les sessions.
- **Barre de recherche.** Un champ de filtre en haut à droite permet de retrouver n'importe quelle instance de la liste par son nom, au fur et à mesure de la frappe.
- **Saut d'extension par commande.** `/dg tww`, `/dg df`, `/dg sl`, `/dg bfa`, `/dg van` etc. vous amènent directement à l'extension voulue.
- **Tout déplier d'un coup.** `/dg expand` ouvre toutes les entrées de l'extension active ; `/dg reset` les replie toutes.

### Corrections de bugs
- Correction du numéro de version, qui affichait encore 1.3 en jeu alors que l'addon était en 3.0.
- Correction des commandes de carte annoncées mais inactives. `/dg map on` / `/dg map off` sont désormais réelles et reliées au système de waypoint.
- Nettoyage de clés de données dupliquées dans les bases Dragonflight et Shadowlands.
- Ajout de la couleur manquante de l'onglet Vanilla, qui s'affichait en gris.
- Sécurisation du bouton minimap face au `math.atan2` déprécié sur les clients récents.
- La touche Échap ferme maintenant uniquement la fenêtre DgnTracker sans perturber vos autres raccourcis.

### Sous le capot
- La liste des instances recycle désormais ses éléments d'interface au lieu de les recréer à chaque rafraîchissement. Cela supprime une lente accumulation de mémoire sur les longues sessions et rend le changement d'onglet plus fluide.

### Rappel commande
La commande passe de `/tdg` à `/dg`. L'alias `/tibidgn` fonctionne toujours. Tapez `/dg help` pour la liste complète.
