# JetWash Pro — Scaffold e Instruções

Este arquivo descreve o scaffold inicial gerado pelo assistente para o projeto JetWash Pro.

Conteúdo criado:

- `mobile/` — scaffold Flutter mínimo com `pubspec.yaml` e `lib/main.dart`.
- `backend/supabase/schema.sql` — schema SQL inicial para importar no Supabase.

Como usar:

1. Rodar app Flutter (pasta `mobile`):

```bash
cd mobile
flutter pub get
flutter run
```

2. Aplicar schema no Supabase: faça login no dashboard do Supabase, abra SQL Editor e cole o conteúdo de `backend/supabase/schema.sql`.

Próximos passos recomendados:

- Criar projeto Supabase, configurar Auth e Storage.
- Adicionar seed de exemplo (tenant, user, customer) para facilitar testes.
- Implementar RLS (Row Level Security) por `tenant_id`.
- Integrar o app Flutter para carregar `tenant settings` dinamicamente e aplicar tema white-label.
