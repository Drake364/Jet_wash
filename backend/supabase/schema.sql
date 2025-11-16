-- Schema inicial para Supabase / Postgres
-- Tabelas essenciais multi-tenant

create extension if not exists "uuid-ossp";

-- Tenants / contas
create table tenants (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  nome_fantasia text,
  plan text,
  logo_url text,
  primary_color text,
  secondary_color text,
  created_at timestamptz default now()
);

-- Users (autenticação via Supabase Auth, mas tabela para relacionamentos)
create table users (
  id uuid primary key default uuid_generate_v4(),
  tenant_id uuid references tenants(id) on delete cascade,
  email text,
  name text,
  phone text,
  role text,
  created_at timestamptz default now()
);

-- Customers
create table customers (
  id uuid primary key default uuid_generate_v4(),
  tenant_id uuid references tenants(id) on delete cascade,
  name text not null,
  phone text,
  email text,
  cpf_cnpj text,
  notes text,
  created_at timestamptz default now()
);

-- Vehicles
create table vehicles (
  id uuid primary key default uuid_generate_v4(),
  tenant_id uuid references tenants(id) on delete cascade,
  customer_id uuid references customers(id) on delete set null,
  plate text,
  model text,
  color text,
  notes text,
  created_at timestamptz default now()
);

-- Service Orders (OS)
create table service_orders (
  id uuid primary key default uuid_generate_v4(),
  tenant_id uuid references tenants(id) on delete cascade,
  vehicle_id uuid references vehicles(id) on delete set null,
  customer_id uuid references customers(id) on delete set null,
  status text default 'open',
  open_at timestamptz default now(),
  close_at timestamptz,
  total numeric(12,2) default 0,
  assigned_to uuid references users(id),
  notes text
);

-- Checklists / Avarias
create table checklists (
  id uuid primary key default uuid_generate_v4(),
  service_order_id uuid references service_orders(id) on delete cascade,
  item text,
  status text,
  photo_url text,
  notes text
);

-- Photos (armazenamento de fotos via Supabase Storage + registro)
create table photos (
  id uuid primary key default uuid_generate_v4(),
  tenant_id uuid references tenants(id) on delete cascade,
  ref_type text,
  ref_id uuid,
  url text,
  uploaded_by uuid references users(id),
  created_at timestamptz default now()
);

-- Schedules / Agendamentos
create table schedules (
  id uuid primary key default uuid_generate_v4(),
  tenant_id uuid references tenants(id) on delete cascade,
  customer_id uuid references customers(id),
  vehicle_id uuid references vehicles(id),
  scheduled_at timestamptz,
  service_type text,
  status text,
  notes text
);

-- Employees / Comissões
create table employees (
  id uuid primary key default uuid_generate_v4(),
  tenant_id uuid references tenants(id) on delete cascade,
  user_id uuid references users(id),
  role text,
  commission_pct numeric(5,2) default 0
);

-- Transactions / Financeiro
create table transactions (
  id uuid primary key default uuid_generate_v4(),
  tenant_id uuid references tenants(id) on delete cascade,
  type text,
  amount numeric(12,2) not null,
  method text,
  reference text,
  created_at timestamptz default now()
);

-- Audit logs
create table audit_logs (
  id uuid primary key default uuid_generate_v4(),
  tenant_id uuid references tenants(id) on delete cascade,
  user_id uuid references users(id),
  action text,
  meta jsonb,
  created_at timestamptz default now()
);
