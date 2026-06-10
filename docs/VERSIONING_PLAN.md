# VERSIONING PLAN — Dark World

## Current
- version.json at project root
- build_number auto-increments per build
- Semver: MAJOR.MINOR.PATCH

## Version Scheme
- 0.x.x = Prototype/Alpha
- 1.0.0 = First playable release
- 1.x.x = Content updates

## Release Channels
- prototype: Current (0.2.0)
- alpha: When zero-friction Mac + Windows
- beta: Feature complete
- stable: Production ready

## Git Tags
- v0.2.0 = current
- Tag format: v{MAJOR}.{MINOR}.{PATCH}
- Tags trigger release.yml workflow

## Future: Update Manifest
```json
{
  "latest": "0.3.0",
  "downloads": {
    "mac": "https://...",
    "windows": "https://..."
  },
  "patches": [
    {"from": "0.2.0", "to": "0.3.0", "size": "15MB"}
  ]
}
```
