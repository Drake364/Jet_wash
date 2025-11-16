-- CRM Module: Customers, Contacts, Service History, Scheduling
-- Enable RLS for all tables below

-- Customers (already exists in schema.sql, but adding enhancements)
-- ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY "users can view customers in their tenant" ON public.customers
--   FOR SELECT USING (is_user_in_tenant(tenant_id));
-- CREATE POLICY "users can insert customers in their tenant" ON public.customers
--   FOR INSERT WITH CHECK (is_user_in_tenant(tenant_id));
-- CREATE POLICY "users can update customers in their tenant" ON public.customers
--   FOR UPDATE USING (is_user_in_tenant(tenant_id));

-- Contacts (one customer can have multiple contacts)
CREATE TABLE IF NOT EXISTS public.contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  role TEXT, -- e.g., 'gerente', 'proprietário', 'motorista'
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.contacts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users can view contacts in their tenant" ON public.contacts
  FOR SELECT USING (is_user_in_tenant(tenant_id));
CREATE POLICY "users can insert contacts in their tenant" ON public.contacts
  FOR INSERT WITH CHECK (is_user_in_tenant(tenant_id));
CREATE POLICY "users can update contacts in their tenant" ON public.contacts
  FOR UPDATE USING (is_user_in_tenant(tenant_id));

CREATE INDEX idx_contacts_tenant_id ON public.contacts(tenant_id);
CREATE INDEX idx_contacts_customer_id ON public.contacts(customer_id);

-- Service History View (aggregation of service_orders per customer)
-- This is used for quick reference; actual data in service_orders table
-- You can query: SELECT * FROM service_orders WHERE customer_id = '...' ORDER BY created_at DESC

-- Scheduling (enhanced with more fields)
-- Reuse public.schedules if exists, else create here
CREATE TABLE IF NOT EXISTS public.schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  vehicle_id UUID REFERENCES public.vehicles(id) ON DELETE SET NULL,
  scheduled_date DATE NOT NULL,
  scheduled_time TIME,
  service_type TEXT, -- e.g., 'lavagem completa', 'polimento'
  status TEXT DEFAULT 'agendado', -- 'agendado', 'concluído', 'cancelado', 'adiado'
  notes TEXT,
  created_by UUID REFERENCES public.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.schedules ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users can view schedules in their tenant" ON public.schedules
  FOR SELECT USING (is_user_in_tenant(tenant_id));
CREATE POLICY "users can insert schedules in their tenant" ON public.schedules
  FOR INSERT WITH CHECK (is_user_in_tenant(tenant_id));
CREATE POLICY "users can update schedules in their tenant" ON public.schedules
  FOR UPDATE USING (is_user_in_tenant(tenant_id));

CREATE INDEX idx_schedules_tenant_id ON public.schedules(tenant_id);
CREATE INDEX idx_schedules_customer_id ON public.schedules(customer_id);
CREATE INDEX idx_schedules_scheduled_date ON public.schedules(scheduled_date);

-- WhatsApp Messages Log (optional, for audit/integration)
CREATE TABLE IF NOT EXISTS public.whatsapp_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  contact_id UUID REFERENCES public.contacts(id) ON DELETE SET NULL,
  message_type TEXT, -- 'confirmacao_agendamento', 'lembrete', 'notificacao_conclusao'
  message_text TEXT NOT NULL,
  phone_number TEXT,
  status TEXT DEFAULT 'enviado', -- 'enviado', 'entregue', 'lido', 'erro'
  sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.whatsapp_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users can view whatsapp_messages in their tenant" ON public.whatsapp_messages
  FOR SELECT USING (is_user_in_tenant(tenant_id));
CREATE POLICY "users can insert whatsapp_messages in their tenant" ON public.whatsapp_messages
  FOR INSERT WITH CHECK (is_user_in_tenant(tenant_id));

CREATE INDEX idx_whatsapp_messages_tenant_id ON public.whatsapp_messages(tenant_id);
CREATE INDEX idx_whatsapp_messages_customer_id ON public.whatsapp_messages(customer_id);

-- RPC to get customer service history
CREATE OR REPLACE FUNCTION public.get_customer_service_history(p_tenant UUID, p_customer_id UUID)
RETURNS TABLE (
  id UUID,
  plate TEXT,
  service_type TEXT,
  total_price NUMERIC,
  status TEXT,
  created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    so.id,
    v.plate,
    so.service_type,
    so.total_price,
    so.status,
    so.created_at
  FROM public.service_orders so
  JOIN public.vehicles v ON so.vehicle_id = v.id
  WHERE so.tenant_id = p_tenant
    AND so.customer_id = p_customer_id
  ORDER BY so.created_at DESC
  LIMIT 50;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC to send WhatsApp notification (stub; actual integration with WhatsApp API)
CREATE OR REPLACE FUNCTION public.send_whatsapp_notification(
  p_tenant UUID,
  p_customer_id UUID,
  p_phone TEXT,
  p_message_type TEXT,
  p_message_text TEXT
)
RETURNS UUID AS $$
DECLARE
  msg_id UUID;
BEGIN
  INSERT INTO public.whatsapp_messages (tenant_id, customer_id, phone_number, message_type, message_text)
  VALUES (p_tenant, p_customer_id, p_phone, p_message_type, p_message_text)
  RETURNING whatsapp_messages.id INTO msg_id;
  
  -- TODO: integrate with WhatsApp Business API here
  -- For now, just log the intent
  
  RETURN msg_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
