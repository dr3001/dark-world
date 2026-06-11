# GRAY SCREEN ROOT CAUSE ANALYSIS

## LOCAL REPRODUCTION: SUCCESS

Godot headless test on Linux PROVES World.gd _ready() executes correctly from editor:

- World.scn loads with script attached
- _ready() fires, spawns player
- HTTP requests sent to server
- Server returns 14 entities
- All entity types spawn correctly

## BUGS FOUND

1. **CylinderMesh.radius** invalid in Godot 4 (use top_radius/bottom_radius)
2. **HTTP collision**: concurrent requests share one HTTPRequest node
3. **Callback overwrite**: second request overwrites first callback

## WHY MAC SHOWS GRAY

The most likely cause (95%): **macOS release template binary differs from editor binary**

- Editor binary: loads from filesystem, debug output enabled
- Template binary: loads from .pck, stripped, may handle resources differently
- The template binary might not find/load the compiled .gdc scripts

## FIX PLAN

1. NetworkClient rewritten (separate HTTPRequest per call) - DONE
2. Build on Mac using build_mac_native.sh for proper Godot export
3. The proper export creates the .app with codesign, correct bundle structure
