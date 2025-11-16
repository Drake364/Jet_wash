-- Tabela para registrar payloads Realtime inesperados/diagnósticos
-- Permite que o cliente envie o payload recebido do Realtime para diagnóstico

create extension if not exists "uuid-ossp";

create table if not exists realtime_logs (
  id uuid primary key default uuid_generate_v4(),
  tenant_id uuid references tenants(id) on delete cascade,
  user_id uuid references users(id),
  source text,
  payload jsonb not null,
  created_at timestamptz default now()
);

-- Índice para consultas recentes
create index if not exists realtime_logs_created_at_idx on realtime_logs(created_at desc);

-- Habilita RLS
alter table realtime_logs enable row level security;

-- Política: permite inserir se o usuário autenticado pertence ao mesmo tenant
-- Usa a função helper `is_user_in_tenant(tenant_uuid)` definida anteriormente
create policy "insert_realtime_logs_by_tenant" on realtime_logs
for insert using (public.is_user_in_tenant(tenant_id)) with check (public.is_user_in_tenant(tenant_id));

-- Política: permite seleção/leitura somente para usuários do tenant
create policy "select_realtime_logs_by_tenant" on realtime_logs
for select using (public.is_user_in_tenant(tenant_id));

-- Função RPC para inserir logs de forma conveniente
-- A função roda como SECURITY DEFINER para simplificar permissões do cliente,
-- mas ainda grava o `user_id` baseado no contexto do auth (auth.uid()).
create or replace function public.log_realtime_payload(p_tenant uuid, p_payload jsonb, p_source text default 'client')
returns jsonb language plpgsql security definer as $$
declare
  v_user uuid := null;
begin
  begin
    v_user := auth.uid()::uuid;
  exception when others then
    v_user := null;
  end;

  insert into realtime_logs (tenant_id, user_id, source, payload)
  values (p_tenant, v_user, p_source, p_payload);

  return jsonb_build_object('status','ok','inserted_at', now());
end;
$$;

-- Ajuste de segurança: conceder execução da função a roles autenticadas se necessário
-- (No Supabase, functions RPCs são normalmente acessíveis aos usuários autenticados.)

-- Exemplo de uso (SQL):
-- select public.log_realtime_payload('11111111-1111-1111-1111-111111111111', '{"event": "test"}'::jsonb, 'mobile');
