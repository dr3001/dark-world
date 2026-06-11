# Dark World — Brevo Integration
## Status: PREPARADO — nao ativado
## Env vars em .env.example:
- BREVO_API_KEY= (preencher com chave da Brevo)
- BREVO_SENDER=noreply@zorionlabs.net
- BREVO_TEMPLATE_VERIFY= (ID do template de verificacao de email)
- BREVO_TEMPLATE_RESET= (ID do template de reset de senha)
## Endpoints que retornam status Brevo:
- POST /auth/register-email → brevo: "configured" ou "not_configured"
- POST /auth/reset-password → brevo: "configured" ou "not_configured"
## Para ativar: preencher BREVO_API_KEY no .env do servidor
