-- Seeds de exemplo para Supabase (JetWash Pro)
-- Insira no SQL Editor do Supabase ou via CLI

-- Exemplo: criar um tenant, um usuário (id deve ser igual ao auth.uid() quando usar Supabase Auth), cliente, veículo e uma OS

insert into tenants (id, name, nome_fantasia, plan, primary_color, created_at)
values (
  '11111111-1111-1111-1111-111111111111',
  'jetwash-tenant',
  'JetWash Demo',
  'free',
  '#1E88E5',
  now()
)
on conflict (id) do nothing;

-- Usuário exemplo: use o mesmo UUID do usuário criado no Supabase Auth
insert into users (id, tenant_id, email, name, phone, role, created_at)
values (
  '22222222-2222-2222-2222-222222222222',
  '11111111-1111-1111-1111-111111111111',
  'admin@example.com',
  'Admin Demo',
  '+5511999999999',
  'admin',
  now()
)
on conflict (id) do nothing;

-- Cliente de exemplo
insert into customers (id, tenant_id, name, phone, email, cpf_cnpj, notes, created_at)
values (
  '33333333-3333-3333-3333-333333333333',
  '11111111-1111-1111-1111-111111111111',
  'João Silva',
  '+5511988887777',
  'joao@example.com',
  '123.456.789-00',
  'Cliente demo',
  now()
)
on conflict (id) do nothing;

-- Veículo de exemplo
insert into vehicles (id, tenant_id, customer_id, plate, model, color, notes, created_at)
values (
  '44444444-4444-4444-4444-444444444444',
  '11111111-1111-1111-1111-111111111111',
  '33333333-3333-3333-3333-333333333333',
  'ABC1D23',
  'Fiat Uno',
  'Branco',
  'Veículo demo',
  now()
)
on conflict (id) do nothing;

-- Ordem de Serviço de exemplo
insert into service_orders (id, tenant_id, vehicle_id, customer_id, status, open_at, total, notes)
values (
  '55555555-5555-5555-5555-555555555555',
  '11111111-1111-1111-1111-111111111111',
  '44444444-4444-4444-4444-444444444444',
  '33333333-3333-3333-3333-333333333333',
  'open',
  now(),
  0,
  'OS demo'
)
on conflict (id) do nothing;

-- Exemplo de transação (pagamento)
insert into transactions (id, tenant_id, type, amount, method, reference, created_at)
values (
  '66666666-6666-6666-6666-666666666666',
  '11111111-1111-1111-1111-111111111111',
  'payment',
  120.00,
  'cash',
  'OS:55555555-5555-5555-5555-555555555555',
  now()
)
on conflict (id) do nothing;

-- Nota: substitua os UUIDs pelos gerados no seu ambiente ou use a CLI para criar usuários no Auth e usar os mesmos IDs.
