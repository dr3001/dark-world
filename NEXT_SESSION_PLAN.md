# NEXT SESSION PLAN — Dark World

## Priority 1: Fix falling (CRITICAL)
1. Add StaticBody3D + CollisionShape3D to Ground mesh in World.tscn
2. Verify player lands on ground and can walk
3. Add collision to plaza, houses, castle

## Priority 2: Validate core gameplay
1. Player spawns on solid ground — walk WASD, run Shift, jump Space
2. Camera follows properly — view should show world
3. Walk to dragon (30m) — verify visible
4. Walk to castle — verify visible
5. Walk to village houses — verify visible
6. NPCs found at plaza — verify labels visible

## Priority 3: Combat validation
1. Click dragon — verify damage dealt
2. Dragon AI — verify it reacts (chase/attack)
3. Kill dragon — verify HP reaches zero and dragon dies
4. Quest completion — verify "Missao concluida" message

## Priority 4: Polish
1. Adjust camera distance/height for best RPG view
2. Adjust lighting for atmosphere
3. Add basic sound effects (footsteps, combat, ambient)
4. World boundary — prevent player from leaving 1000x1000 area
