# PLAYER JOURNEY REPORT — Mission 6.1

## Full Flow Executed (via API)

| Step | Action | API Call | Result |
|------|--------|----------|--------|
| 1 | Register | POST /auth/register | JWT token |
| 2 | Create account | POST /test/account | account_id |
| 3 | Create character | POST /test/character | entity_id, alive |
| 4 | Enter world | GET /worlds/:id/entities | 6 entities |
| 5 | View dragon | GET /dragons | Vorak, o Antigo |
| 6 | View territory | In entities | Vale Cinzento |
| 7 | Death | POST /events/character-died | Enqueued |
| 8 | Process death | Engine tick | life_state: afterlife |
| 9 | Afterlife world | GET /characters/:id | Mundo Congelado |
| 10 | Return | POST /events/afterlife-returned | Enqueued |
| 11 | Process return | Engine tick | life_state: returned |
| 12 | Back to living | GET /characters/:id | Mundo dos Vivos |

## 12/12 Steps PASS
