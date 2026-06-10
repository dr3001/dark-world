# MISSION 8 — DNS & PORTAL AUDIT

## DNS Resolution
| Domain | DNS | Status |
|--------|-----|--------|
| zorionlabs.net | Cloudflare (104.21.85.144, 172.67.206.169) | FUNCIONAL |
| www.zorionlabs.net | Cloudflare | FUNCIONAL |
| dark.zorionlabs.net | NXDOMAIN | NAO CONFIGURADO |
| app.zorionlabs.net | Cloudflare | FUNCIONAL |
| cloud.zorionlabs.net | Cloudflare | FUNCIONAL |

## Portal URLs (zorionlabs.net)
| URL | HTTP | Status |
|-----|------|--------|
| /dark/ | 200 | FUNCIONAL |
| /dark/downloads/ | 200 | FUNCIONAL |
| /dark/status/ | 200 | FUNCIONAL |
| /dark/docs/ | 200 | FUNCIONAL |
| /dark/reports/ | 200 | FUNCIONAL |
| /dark/evidence/ | 200 | FUNCIONAL |
| /dark/register/ | 200 | FUNCIONAL |
| /dark/login/ | 200 | FUNCIONAL |
| /dark/how-to-play-mac/ | 200 | FUNCIONAL |
| /darkworld/ | 200 | FUNCIONAL |

## dark.zorionlabs.net DNS Required
Para ativar dark.zorionlabs.net, criar registro no Cloudflare:
- Type: A
- Name: dark
- Content: 5.78.142.138
- Proxy: ON (orange cloud)
- TTL: Auto

O nginx ja esta configurado para responder a dark.zorionlabs.net.
