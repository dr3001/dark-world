# APPLE SIGNING REPORT — Mission 7.2

## Current State
| Item | Value |
|------|-------|
| Signed | NO |
| Certificate | None |
| Ad-hoc possible | YES (codesign --sign -) |
| Developer ID needed | YES (for notarization) |

## What works without Apple Developer
1. Ad-hoc signing: 
2. Right-click → Open bypasses Gatekeeper after quarantine removal
3. End users need to do this manually

## What requires Apple Developer (9/year)
1. Developer ID certificate signing
2. Notarization (required for seamless open)
3. No Gatekeeper warnings
4. Direct double-click to open

## Path Forward
1. Short term: Document xattr + codesign ad-hoc for users
2. Medium term: Get Apple Developer Program membership
3. Long term: Sign + notarize all builds
