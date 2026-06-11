# BUGS REMAINING — Dark World

## CONFIRMED

### BUG-1: Player falls through ground (CRITICAL)
**Symptom:** Player spawns at Y=2, immediately falls due to gravity, appears to fall forever
**Cause:** Ground MeshInstance3D has NO collision body. CharacterBody3D with move_and_slide() requires StaticBody3D or other physics bodies to collide with.
**Evidence:** PlayerController has gravity=20.0, jump_velocity=8.0, uses move_and_slide(). Ground node is a plain MeshInstance3D with no StaticBody3D child.
**Fix:** Add StaticBody3D + CollisionShape3D (BoxShape or WorldBoundaryShape) to Ground, or convert Ground to a StaticBody3D directly.

### BUG-2: Camera/Player disorientation after fall
**Symptom:** After player falls through ground, camera follows player into void, making the scene unintelligible.
**Cause:** Consequence of BUG-1. Camera targets player position, which goes below ground.
**Fix:** Fix BUG-1 first; camera will naturally show correct view.

### BUG-3: No collision on any world object
**Symptom:** Houses, trees, castle, fountain — all are visual only, no physics collision.
**Cause:** All world objects are MeshInstance3D without StaticBody3D children.
**Fix:** Add simple collision shapes to major objects (houses, castle, fountain, trees).

## OBSERVED (needs verification)
- Dragon BlueDemon.gltf may appear inverted or too large/small
- NPC labels may clip through geometry
- Camera may be too close to player on startup
