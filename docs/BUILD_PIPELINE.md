# BUILD PIPELINE — Dark World

## Architecture

```
Developer (OpenCode)
    |
    v
git commit + push
    |
    v
GitHub Actions
    |
    +---> build-windows.yml (on push)
    |         |
    |         v
    |     Godot 4.6.3 (Linux runner)
    |         |
    |         v
    |     DarkWorld.exe + DarkWorld.pck
    |         |
    |         v
    |     DarkWorld-Windows.zip (artifact)
    |
    +---> build-mac.yml (on push)
    |         |
    |         v
    |     Godot 4.6.3 (Linux runner)
    |         |
    |         v
    |     DarkWorld.app (unsigned)
    |         |
    |         v
    |     DarkWorld-Mac.tar.gz / .zip (artifact)
    |
    +---> release.yml (on tag v*)
              |
              v
          Build ALL platforms
              |
              v
          Create GitHub Release
              |
              v
          Upload to downloads server
```

## Workflows

| Workflow | Trigger | Output |
|----------|---------|--------|
| build-windows.yml | push to main/develop | DarkWorld-Windows.zip |
| build-mac.yml | push to main/develop | DarkWorld-Mac.tar.gz |
| release.yml | tag v* | GitHub Release with all builds |

## Future: Mac Signed Builds

```
GitHub Actions (macOS runner, $0.08/min)
    |
    v
Godot 4.6.3 (macOS)
    |
    v
codesign --force --deep --sign "Developer ID"
    |
    v
hdiutil create DarkWorld.dmg
    |
    v
xcrun notarytool submit
```

Requires:
- macOS runner (GitHub Actions: free for public repos)
- Apple Developer Program ($99/year)
- Developer ID certificate in GitHub Secrets
