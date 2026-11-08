# Western Rush RP Mobile — KLD

Original 3D roleplay game made with Godot 4, set in a Kaliningrad-inspired city.

## Launcher

The project now starts with a landscape 16:9 launcher featuring a custom night-city backdrop, Western Rush RP branding, editable/saved nickname, test-server information, animated vehicle movement, navigation tabs, and a Play button that opens the KLD map. Server population/online status is intentionally not fabricated; live server integration is a later task.

## Open the project

1. Install Godot 4.3 or newer.
2. In Godot Project Manager, choose **Import**.
3. Select this folder's `project.godot`.
4. Press **Play**.

## Current prototype

- Landscape launcher with animated car and nickname persistence.
- Play button opens the playable Kaliningrad map.
- Procedural 3D city blockout with the Pregolya river and three bridges.
- North, central, east, west, south and industrial districts.
- Placeholder landmarks: Victory Square, Prospect Mira, Cathedral, Fish Village, bus station, airport, hospital and police.
- Player character with collision and gravity.
- Third-person follow camera and daylight/ambient lighting.
- Android-style on-screen directional controls with multi-touch support.
- Sprint button; Shift also works when testing with a keyboard.

## Current status

The launcher UI is a functional first pass. News/settings/profile panels currently show informational placeholders. Live server status, player count, account authentication, a drivable vehicle, missions, NPCs, sound, performance profiling and final Android device testing remain future work.

A real game APK must be exported from this `godot/` project with Godot's Android export templates and Android SDK configured.


## Intro video integration

The launcher now routes the first Play action through `scenes/intro.tscn` when
`art/western_rush_intro.ogv` is present. The viewed flag is stored locally in
`user://western_rush.cfg`; after playback (or Skip), the game opens the KLD map.
The Settings tab exposes a button to replay the intro.

**Media asset still required:** place the Android-compatible Ogg Theora video at
`godot/art/western_rush_intro.ogv`. The prepared MP4 must be transcoded to OGV
before it can be used by Godot's built-in VideoStreamPlayer. Until that asset is
added, Play safely opens the map without showing the intro.
