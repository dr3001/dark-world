# Quaternius Asset Download Guide

## How to download (on Mac/local machine)

These packs are on Google Drive. Download them from your Mac browser:

### Essential Packs
1. **Ultimate Monsters** (dragons, creatures):  
   https://drive.google.com/drive/folders/18m4KpzpEzhC9wl7jr6dUc0N8Jozr79C

2. **Stylized Nature MegaKit** (trees, rocks, plants):  
   https://quaternius.com/packs/stylizednaturemegakit.html

3. **Medieval Village MegaKit** (buildings):  
   https://quaternius.com/packs/medievalvillagemegakit.html

4. **Fantasy Props MegaKit** (weapons, items):  
   https://quaternius.com/packs/fantasypropsmegakit.html

### License
All Quaternius assets are **CC0 (Public Domain)**. Free for commercial use.

### After downloading
Copy the .glb/.gltf files to:
- `godot-client/assets/quaternius/creatures/` — dragons, monsters
- `godot-client/assets/quaternius/nature/` — trees, rocks
- `godot-client/assets/quaternius/buildings/` — houses, walls
- `godot-client/assets/quaternius/props/` — furniture, items

Then run: `git add -A && git commit -m "Add Quaternius assets" && git push`
The build server will pick them up on next export.
