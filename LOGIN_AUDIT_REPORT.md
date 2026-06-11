# Dark World — Login Audit Report
## Auth System: Email registration + password hash (scryptSync)
## Endpoints: POST /auth/register-email, /auth/login, /auth/logout, /auth/verify/:token, /auth/reset-password
## Tables: accounts_profile (password_hash, email_verified), auth_sessions, login_history, email_verifications, password_resets
## Security: Failed logins logged to login_history + security_logs, banned accounts rejected
## Brevo: Env vars prepared (BREVO_API_KEY, BREVO_SENDER, BREVO_TEMPLATE_VERIFY, BREVO_TEMPLATE_RESET) — not activated
