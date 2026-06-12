# AUTH_FLOW_REPORT.md

**Date:** 2026-06-12

## Flow matrix

| Flow | Entry | Status |
|------|-------|--------|
| Login in-game | `Login.tscn` + `Main.gd` | Working — user-friendly status messages |
| Create account | Button → portal `/register/` | Working |
| Email verify | Portal `/verify/?token=` | Working |
| Forgot password | **Was missing UI** | **Fixed** |

## Fixes applied

### Portal

- Created `/forgot-password/index.html` on `dark.zorionlabs.net`
- Added link on `/login/` page

### In-game

- Added **Esqueci a senha** button on `Login.tscn`
- `Main.gd` opens `https://dark.zorionlabs.net/forgot-password/`

### API security

- `POST /auth/reset-password` no longer returns `reset_token` or `brevo` debug fields
- Response: `{ ok: true, message: "Se o email existir, enviaremos instrucoes de recuperacao." }`

## Debug removal

- `Main.gd` — status via `GameLogger.write_log()` only, not console
- No technical stack traces shown to player on login screen

## Brevo

Email send depends on `BREVO_API_KEY` on server — not changed in this fix. User sees generic success message regardless (no email enumeration).

## Human retest checklist

- [ ] Login with verified account
- [ ] Register new account via portal
- [ ] Verify email link
- [ ] Request password reset via `/forgot-password/`
