# JetWash Pro — Documentação do Projeto

Este documento fornece instruções rápidas para configurar e rodar o projeto JetWash Pro (mobile Flutter + backend Supabase), além de explicações sobre arquivos importantes e como usar as funcionalidades de diagnóstico (realtime logs, export CSV).

**Visão Geral**
- **Mobile:** Flutter (Dart) usando `supabase_flutter` para autenticação, Realtime e Storage.
- **Backend:** Supabase (Postgres, Auth, Storage, Realtime, Functions/RPC). SQLs estão em `backend/supabase/`.
- **Objetivo:** Multi‑tenant (coluna `tenant_id`) com RLS habilitada para isolar dados por cliente.

**Estrutura principal do repositório**
- `mobile/` — código Flutter.
- `backend/supabase/` — arquivos SQL: `schema.sql`, `rls.sql`, `seeds.sql`, `auth_sync.sql`, `realtime_logs.sql`.
- `DOCUMENTATION.md` — este arquivo.

Recomendações rápidas antes de começar
- Ter uma conta/projeto Supabase criado.
- Ter Flutter SDK instalado (recomendo Flutter 3.7+; adapte conforme seu ambiente).

1) Configurar o Supabase (executar SQLs)

Dentro do painel do seu projeto Supabase (SQL Editor) ou usando `supabase` CLI, execute os arquivos SQL na ordem abaixo:

1. `backend/supabase/schema.sql` — cria tabelas principais (`tenants`, `users`, `service_orders`, etc.).
2. `backend/supabase/rls.sql` — habilita RLS e cria a função `public.is_user_in_tenant` e políticas.
3. `backend/supabase/realtime_logs.sql` — cria a tabela `realtime_logs` e a RPC `log_realtime_payload` usada pelo app para captura de payloads desconhecidos.
4. `backend/supabase/auth_sync.sql` — trigger para sincronizar `auth.users` -> `public.users`.
5. `backend/supabase/seeds.sql` — insere dados de demonstração (opcional).

Observação: se preferir, execute via CLI (`supabase sql`) ou cole os conteúdos no SQL Editor do Supabase.

2) Configurar variáveis de ambiente do mobile

No diretório `mobile/` crie um arquivo `.env` (não comitar) com ao menos:

```
SUPABASE_URL=https://<your-project>.supabase.co
SUPABASE_ANON_KEY=<anon-public-key>
```

3) Rodar o app Flutter (desenvolvimento)

Abra um terminal no diretório `mobile`:

```bash
cd mobile
flutter pub get
flutter run
```

Para rodar testes:

```bash
flutter test
```

4) Funcionalidades importantes e onde estão

- **Autenticação:** `mobile/lib/auth_service.dart` + `mobile/lib/auth_page.dart`.
- **Onboarding/white‑label:** `mobile/lib/onboarding_page.dart` — permite subir logo/cor e gravar no tenant.
- **Storage / Uploads:** `mobile/lib/storage_service.dart` — salva paths no DB e gera signed URLs quando necessário.
- **OCR:** `mobile/lib/ocr_service.dart` — usa ML Kit on‑device; há heurísticas e fallback planejado para serviço externo.
- **Pátio / Realtime:** `mobile/lib/parking_page.dart` — subscribe em `service_orders` e aplica patches incrementais; logs desconhecidos são enviados à RPC `log_realtime_payload`.
- **Realtime Logs UI:** `mobile/lib/realtime_logs_page.dart` — lista últimos logs; botão de export CSV integrado.
- **Export CSV:** `mobile/lib/csv_export_service.dart` — gera CSV em diretório temporário do dispositivo e retorna caminho.

5) Debug e diagnóstico

- Se a interface do Pátio não atualizar como esperado, abra o console do Flutter (logs) — o listener do Realtime imprime payloads desconhecidos.
- Use a tela `Realtime Logs` no app para visualizar os últimos payloads armazenados no servidor (tabela `realtime_logs`).
- Para exportar logs, abra `Realtime Logs` e toque no ícone de download; o app gerará um arquivo CSV em `getTemporaryDirectory()` e mostrará o caminho.

6) Permissões nativas e Fastlane

- O projeto contém exemplos e notas sobre permissões (câmera/storage) e um `mobile/fastlane/Fastfile` simples para builds. Ajuste conforme suas credenciais e certificados.

7) Próximos passos e recomendações

- Implementar endpoints/edge function para gerar signed URLs server‑side (opcional) e reduzir exposição de anon keys.
- Criar pipeline CI (GitHub Actions) para rodar `flutter analyze`, `flutter test`, e builds de release via Fastlane.
- Avançar módulos: CRM, Equipe, Financeiro e integrações (WhatsApp, pagamentos, NFS‑e).

8) Onde aplicar mudanças DB e testes

- Sempre aplique `backend/supabase/*.sql` no ambiente de staging antes de production.
- Mantenha seeds como referência, não aplique em produção sem revisar IDs/keys.

9) Contato / ajuda

Se quiser que eu gere um README mais enxuto, um `docs/` com tutoriais passo‑a‑passo, ou automatize a execução das SQLs com `supabase` CLI e scripts, diga qual prefere que eu implemente em seguida.

---
Arquivo criado automaticamente pela assistência; adapte conforme seu fluxo e políticas de segurança (chaves/anon keys).
