# VFX 01 — Blood Slash

Blender source: tools/vfx_source/blood_slash.blend
Godot runtime: scripts/skills/blood_slash.gd
Integration: FighterController._release_attack()
Preview: art/vfx/slash_preview.png
Unity companion: D:/ponly/BloodGambit-VFX-Unity

Run animated Godot preview from this project directory:
./Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/preview_slash.gd

The ribbon uses two additive layers, three guard directions, and a larger,
longer heavy attack. Effects belong to skill_effects for duel cleanup and
free themselves after 0.18 / 0.26 seconds. No damage values are changed.
The preview is isolated; weapon alignment during live duels still needs playtesting.

Rebuild mesh with Blender:
blender --background --python tools/build_slash.py

Unity uses the FBX with its own additive material and looping preview component.
It is a separate preview project; the playable game remains in Godot.
