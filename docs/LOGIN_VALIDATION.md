# LOGIN VALIDATION — Mission 6.1

## Nakama Authentication (Real JWT)

### Register
```
POST /auth/register
Body: {"device_id": "player-xyz"}
Response: {"token": "eyJ...", "created": true, "user_id": "uuid"}
Status: 201
```

### Restore Session
```
POST /auth/restore
Body: {"token": "eyJ..."}
Response: {"account": {...}}
Status: 200 (valid) / 401 (invalid)
```

## Test Results
| Step | Result |
|------|--------|
| Create account | created:true, JWT token |
| Token format | Valid JWT (HS256) |
| Session restore | 200 with account data |
| Invalid token | 401 error |

## Verdito: FUNCIONAL
Autenticacao real via Nakama 3.31 com JWT tokens.
