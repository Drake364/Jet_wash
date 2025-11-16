-- Team Management Module: Roles, Access Control, Commissions
-- Extend public.users table with role management

-- Add columns to users table (if not already present)
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'funcionario', -- 'admin', 'gerente', 'funcionario'
ADD COLUMN IF NOT EXISTS commission_rate NUMERIC DEFAULT 0.05, -- e.g., 5% per completed service order
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

-- Commission Records (tracks auto-calculated commissions)
CREATE TABLE IF NOT EXISTS public.commissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  employee_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  service_order_id UUID REFERENCES public.service_orders(id) ON DELETE SET NULL,
  amount NUMERIC NOT NULL,
  period_start DATE,
  period_end DATE,
  status TEXT DEFAULT 'pendente', -- 'pendente', 'aprovado', 'pago'
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.commissions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users can view commissions in their tenant" ON public.commissions
  FOR SELECT USING (is_user_in_tenant(tenant_id));
CREATE POLICY "users can view own commissions" ON public.commissions
  FOR SELECT USING (is_user_in_tenant(tenant_id) AND (employee_id = auth.uid() OR (SELECT role FROM public.users WHERE id = auth.uid() LIMIT 1) = 'admin'));
CREATE POLICY "admins can insert commissions in their tenant" ON public.commissions
  FOR INSERT WITH CHECK (is_user_in_tenant(tenant_id) AND (SELECT role FROM public.users WHERE id = auth.uid() LIMIT 1) IN ('admin', 'gerente'));
CREATE POLICY "admins can update commissions in their tenant" ON public.commissions
  FOR UPDATE USING (is_user_in_tenant(tenant_id) AND (SELECT role FROM public.users WHERE id = auth.uid() LIMIT 1) IN ('admin', 'gerente'));

CREATE INDEX idx_commissions_tenant_id ON public.commissions(tenant_id);
CREATE INDEX idx_commissions_employee_id ON public.commissions(employee_id);
CREATE INDEX idx_commissions_period ON public.commissions(period_start, period_end);

-- Productivity Log (tracks employee actions for reporting)
CREATE TABLE IF NOT EXISTS public.productivity_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  employee_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  action_type TEXT, -- 'service_order_completed', 'photo_uploaded', 'checklist_item_checked'
  service_order_id UUID REFERENCES public.service_orders(id) ON DELETE SET NULL,
  details JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.productivity_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users can view productivity_log in their tenant" ON public.productivity_log
  FOR SELECT USING (is_user_in_tenant(tenant_id));
CREATE POLICY "employees can view own productivity_log" ON public.productivity_log
  FOR SELECT USING (is_user_in_tenant(tenant_id) AND (employee_id = auth.uid() OR (SELECT role FROM public.users WHERE id = auth.uid() LIMIT 1) IN ('admin', 'gerente')));

CREATE INDEX idx_productivity_log_tenant_id ON public.productivity_log(tenant_id);
CREATE INDEX idx_productivity_log_employee_id ON public.productivity_log(employee_id);
CREATE INDEX idx_productivity_log_created_at ON public.productivity_log(created_at);

-- RPC to calculate commissions for a given period
CREATE OR REPLACE FUNCTION public.calculate_commissions(
  p_tenant UUID,
  p_employee_id UUID,
  p_period_start DATE,
  p_period_end DATE
)
RETURNS NUMERIC AS $$
DECLARE
  total_commission NUMERIC := 0;
  commission_rate NUMERIC;
BEGIN
  -- Get employee's commission rate
  SELECT users.commission_rate INTO commission_rate
  FROM public.users
  WHERE id = p_employee_id AND tenant_id = p_tenant;
  
  -- Calculate total from completed service orders
  SELECT COALESCE(SUM(so.total_price * commission_rate), 0) INTO total_commission
  FROM public.service_orders so
  WHERE so.tenant_id = p_tenant
    AND so.employee_id = p_employee_id
    AND so.status = 'concluido'
    AND DATE(so.completed_at) >= p_period_start
    AND DATE(so.completed_at) <= p_period_end;
  
  RETURN total_commission;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC to get employee productivity summary
CREATE OR REPLACE FUNCTION public.get_employee_productivity(
  p_tenant UUID,
  p_employee_id UUID,
  p_period_start DATE,
  p_period_end DATE
)
RETURNS TABLE (
  completed_orders INT,
  total_revenue NUMERIC,
  avg_order_value NUMERIC,
  photos_uploaded INT,
  commission_earned NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COALESCE(COUNT(DISTINCT so.id), 0)::INT as completed_orders,
    COALESCE(SUM(so.total_price), 0) as total_revenue,
    COALESCE(AVG(so.total_price), 0) as avg_order_value,
    COALESCE(COUNT(DISTINCT p.id), 0)::INT as photos_uploaded,
    public.calculate_commissions(p_tenant, p_employee_id, p_period_start, p_period_end) as commission_earned
  FROM public.service_orders so
  LEFT JOIN public.photos p ON so.id = p.service_order_id
  WHERE so.tenant_id = p_tenant
    AND so.employee_id = p_employee_id
    AND so.status = 'concluido'
    AND DATE(so.completed_at) >= p_period_start
    AND DATE(so.completed_at) <= p_period_end;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-log productivity
CREATE OR REPLACE FUNCTION public.log_productivity()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_TABLE_NAME = 'service_orders' AND NEW.status = 'concluido' THEN
    INSERT INTO public.productivity_log (tenant_id, employee_id, action_type, service_order_id, details)
    VALUES (NEW.tenant_id, NEW.employee_id, 'service_order_completed', NEW.id, 
            jsonb_build_object('total_price', NEW.total_price, 'service_type', NEW.service_type));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_log_productivity
AFTER UPDATE ON public.service_orders
FOR EACH ROW
EXECUTE FUNCTION public.log_productivity();
