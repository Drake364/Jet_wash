# JetWash Pro

Sistema de gestão para lava-jato — SaaS + Mobile

## Visão rápida
- App mobile Flutter (multi-tenant, white-label, OCR, Pátio digital, checklist com fotos)
- Backend Supabase (Postgres, Auth, Storage, Realtime, RLS)
- Diagnóstico de eventos Realtime e exportação de logs

## Como começar
1. Crie um projeto Supabase e execute os SQLs em `backend/supabase/` na ordem:
	- `schema.sql`, `rls.sql`, `realtime_logs.sql`, `auth_sync.sql`, `seeds.sql` (opcional)
2. No diretório `mobile/`, crie `.env` com:
	```
	SUPABASE_URL=https://<your-project>.supabase.co
	SUPABASE_ANON_KEY=<anon-public-key>
	```
3. Rode o app:
	```bash
	cd mobile
	flutter pub get
	flutter run
	```

## Funcionalidades principais
- Autenticação (signup/login)
- Onboarding white-label (logo, cor, nome)
- Upload de fotos/checklist
- OCR de placas (ML Kit)
- Pátio digital com atualização em tempo real
- Diagnóstico de eventos Realtime (logs + export CSV)

## Documentação detalhada
Consulte `DOCUMENTATION.md` para instruções completas de setup, uso e diagnóstico.

---
Projeto em desenvolvimento. Para dúvidas, sugestões ou bugs, abra uma issue ou consulte a documentação.
