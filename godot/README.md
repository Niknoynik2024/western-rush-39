# Western Rush RP Mobile — KLD

Original 3D roleplay game made with Godot 4, set in a Kaliningrad-inspired city.

## Open the project

1. Install Godot 4.3 or newer.
2. In Godot Project Manager, choose **Import**.
3. Select this folder's `project.godot`.
4. Press **Play**.

## Current prototype

- Procedural 3D city blockout with the Pregolya river and three bridges.
- North, central, east, west, south and industrial districts.
- Placeholder landmarks: Victory Square, Prospect Mira, Cathedral, Fish Village, bus station, airport, hospital and police.
- Player character with collision and gravity.
- Third-person follow camera and basic daylight/ambient lighting.
- Android-style on-screen directional controls with multi-touch support.
- Sprint button; Shift also works when testing with a keyboard.

## Current status

The project now has the first playable mobile-control pass. It is still a prototype: city buildings are procedural placeholders, and vehicles, missions, NPCs, account/server systems, sound, performance profiling and Android export configuration remain to be implemented.

**Important:** the separate `app/` Android launcher APK is not this Godot game. A real game APK must be exported from this `godot/` project with Godot's Android export templates and Android SDK configured.

## Next development milestones

1. Configure a repeatable Android export and produce a test APK from this Godot project.
2. Add a proper virtual joystick, camera controls and a player animation.
3. Add the first drivable vehicle and a small interaction/mission loop.
4. Optimize the city for Android devices (draw calls, collision, visibility and memory).
