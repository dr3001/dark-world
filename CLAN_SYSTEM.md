# Dark World — Clan System
## Roles: leader, officer, member
## Tabelas: clans (name, tag, leader, member_count, level), clan_members, clan_invites
## API: GET /clans, POST /clans/create, POST /clans/:id/join, POST /clans/:id/leave, GET /clans/:id/members
## Invite: pending → accepted/declined/expired (7 dias TTL)
## Ranking: GET /rankings/clans (por level e member_count)
