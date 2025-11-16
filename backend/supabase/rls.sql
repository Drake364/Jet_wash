-- Políticas RLS (Row Level Security) para multitenancy básico
-- Atenção: revise e adapte conforme mapeamento entre Supabase Auth e tabela `users`

-- Ativa RLS nas tabelas que possuem tenant_id
alter table tenants enable row level security;
alter table users enable row level security;
alter table customers enable row level security;
alter table vehicles enable row level security;
alter table service_orders enable row level security;
alter table checklists enable row level security;
alter table photos enable row level security;
alter table schedules enable row level security;
alter table employees enable row level security;
alter table transactions enable row level security;
alter table audit_logs enable row level security;

-- Política de leitura/escrita por tenant: permite acesso se o usuário autenticado pertence ao mesmo tenant
-- Pressupõe que `users.id` corresponde ao `auth.uid()` do Supabase Auth

-- Helper: checa associação do usuário logado com o tenant
create or replace function public.is_user_in_tenant(tenant_uuid uuid)
returns boolean language sql stable as $$
  select exists (
    select 1 from users u
    where u.id = auth.uid()::uuid and u.tenant_id = tenant_uuid
  );
$$;

-- Policy para customers
create policy "tenant_access_customers" on customers
for all using (public.is_user_in_tenant(tenant_id)) with check (public.is_user_in_tenant(tenant_id));

-- Policy para vehicles
create policy "tenant_access_vehicles" on vehicles
for all using (public.is_user_in_tenant(tenant_id)) with check (public.is_user_in_tenant(tenant_id));

-- Policy para service_orders
create policy "tenant_access_service_orders" on service_orders
for all using (public.is_user_in_tenant(tenant_id)) with check (public.is_user_in_tenant(tenant_id));

-- Policy para transactions
create policy "tenant_access_transactions" on transactions
for all using (public.is_user_in_tenant(tenant_id)) with check (public.is_user_in_tenant(tenant_id));

-- Policy para photos
create policy "tenant_access_photos" on photos
for all using (public.is_user_in_tenant(tenant_id)) with check (public.is_user_in_tenant(tenant_id));

-- Policy para checklists (obtém tenant via service_orders)
create or replace function public.checklist_tenant(checklist_id uuid)
returns uuid language sql stable as $$
  select so.tenant_id from checklists c
  join service_orders so on so.id = c.service_order_id
  where c.id = checklist_id
  limit 1;
$$;

create policy "tenant_access_checklists" on checklists
for all using (
  (exists (select 1 from service_orders so where so.id = service_order_id and public.is_user_in_tenant(so.tenant_id)))
) with check (
  (exists (select 1 from service_orders so where so.id = service_order_id and public.is_user_in_tenant(so.tenant_id)))
);

-- Policy para schedules
create policy "tenant_access_schedules" on schedules
for all using (public.is_user_in_tenant(tenant_id)) with check (public.is_user_in_tenant(tenant_id));

-- Policy para employees
create policy "tenant_access_employees" on employees
for all using (public.is_user_in_tenant(tenant_id)) with check (public.is_user_in_tenant(tenant_id));

-- Policy para audit_logs
create policy "tenant_access_audit_logs" on audit_logs
for select using (public.is_user_in_tenant(tenant_id));

-- Nota: itens administrativos (ex.: criação de tenants) devem ser tratados separadamente e geralmente exigem role/privilege específicos.
