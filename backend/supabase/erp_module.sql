-- ERP/Finance Module: Cash Flow, Accounts Payable/Receivable, Reporting
-- Extend public.transactions table and add related financial tables

-- Enhanced Transactions (already in schema.sql, adding more fields here for clarity)
-- ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS category TEXT;
-- ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS notes TEXT;

-- Accounts Payable (supplier/vendor expenses)
CREATE TABLE IF NOT EXISTS public.accounts_payable (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  vendor_name TEXT NOT NULL,
  amount NUMERIC NOT NULL,
  due_date DATE,
  paid_date DATE,
  status TEXT DEFAULT 'pendente', -- 'pendente', 'pago', 'cancelado'
  category TEXT, -- 'fornecedores', 'servicos', 'aluguel', etc.
  notes TEXT,
  invoice_number TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.accounts_payable ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users can view ap in their tenant" ON public.accounts_payable
  FOR SELECT USING (is_user_in_tenant(tenant_id));
CREATE POLICY "admins/gerente can manage ap in their tenant" ON public.accounts_payable
  FOR ALL USING (is_user_in_tenant(tenant_id) AND (SELECT role FROM public.users WHERE id = auth.uid() LIMIT 1) IN ('admin', 'gerente'));

CREATE INDEX idx_ap_tenant_id ON public.accounts_payable(tenant_id);
CREATE INDEX idx_ap_due_date ON public.accounts_payable(due_date);
CREATE INDEX idx_ap_status ON public.accounts_payable(status);

-- Accounts Receivable (customer payments due)
CREATE TABLE IF NOT EXISTS public.accounts_receivable (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  service_order_id UUID REFERENCES public.service_orders(id) ON DELETE SET NULL,
  amount NUMERIC NOT NULL,
  due_date DATE,
  paid_date DATE,
  status TEXT DEFAULT 'pendente', -- 'pendente', 'pago', 'cancelado', 'vencido'
  payment_method TEXT, -- 'dinheiro', 'cartao', 'pix', 'cheque'
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.accounts_receivable ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users can view ar in their tenant" ON public.accounts_receivable
  FOR SELECT USING (is_user_in_tenant(tenant_id));
CREATE POLICY "admins/gerente can manage ar in their tenant" ON public.accounts_receivable
  FOR ALL USING (is_user_in_tenant(tenant_id) AND (SELECT role FROM public.users WHERE id = auth.uid() LIMIT 1) IN ('admin', 'gerente'));

CREATE INDEX idx_ar_tenant_id ON public.accounts_receivable(tenant_id);
CREATE INDEX idx_ar_customer_id ON public.accounts_receivable(customer_id);
CREATE INDEX idx_ar_due_date ON public.accounts_receivable(due_date);
CREATE INDEX idx_ar_status ON public.accounts_receivable(status);

-- Financial Summary / Dashboard (aggregated view)
-- This is a helper table; normally you'd query transactions on-the-fly
CREATE TABLE IF NOT EXISTS public.financial_summary (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  period_date DATE NOT NULL,
  total_revenue NUMERIC DEFAULT 0,
  total_expenses NUMERIC DEFAULT 0,
  total_payable NUMERIC DEFAULT 0,
  total_receivable NUMERIC DEFAULT 0,
  net_cash_flow NUMERIC DEFAULT 0,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(tenant_id, period_date)
);

ALTER TABLE public.financial_summary ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users can view financial_summary in their tenant" ON public.financial_summary
  FOR SELECT USING (is_user_in_tenant(tenant_id));

CREATE INDEX idx_financial_summary_tenant_id ON public.financial_summary(tenant_id);
CREATE INDEX idx_financial_summary_period_date ON public.financial_summary(period_date);

-- RPC to calculate cash flow for a period
CREATE OR REPLACE FUNCTION public.get_cash_flow(
  p_tenant UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE (
  total_revenue NUMERIC,
  total_expenses NUMERIC,
  total_payable NUMERIC,
  total_receivable NUMERIC,
  net_cash_flow NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COALESCE(SUM(CASE WHEN t.type = 'receita' THEN t.amount ELSE 0 END), 0) as total_revenue,
    COALESCE(SUM(CASE WHEN t.type = 'despesa' THEN t.amount ELSE 0 END), 0) as total_expenses,
    COALESCE(SUM(ap.amount), 0) as total_payable,
    COALESCE(SUM(ar.amount), 0) as total_receivable,
    COALESCE(SUM(CASE WHEN t.type = 'receita' THEN t.amount ELSE -t.amount END), 0) as net_cash_flow
  FROM public.transactions t
  FULL OUTER JOIN public.accounts_payable ap ON t.tenant_id = ap.tenant_id AND t.type = 'despesa'
  FULL OUTER JOIN public.accounts_receivable ar ON t.tenant_id = ar.tenant_id AND ar.status IN ('pendente', 'vencido')
  WHERE t.tenant_id = p_tenant
    AND DATE(t.created_at) >= p_start_date
    AND DATE(t.created_at) <= p_end_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC to get financial summary by category
CREATE OR REPLACE FUNCTION public.get_cash_flow_by_category(
  p_tenant UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE (
  category TEXT,
  type TEXT,
  total_amount NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COALESCE(t.category, 'sem categoria') as category,
    t.type,
    SUM(t.amount) as total_amount
  FROM public.transactions t
  WHERE t.tenant_id = p_tenant
    AND DATE(t.created_at) >= p_start_date
    AND DATE(t.created_at) <= p_end_date
  GROUP BY t.category, t.type
  ORDER BY total_amount DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC to export financial report data (used by mobile app)
CREATE OR REPLACE FUNCTION public.export_financial_report(
  p_tenant UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE (
  report_type TEXT,
  data JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    'cash_flow'::TEXT,
    jsonb_agg(jsonb_build_object(
      'period', p_start_date || ' to ' || p_end_date,
      'total_revenue', (SELECT total_revenue FROM public.get_cash_flow(p_tenant, p_start_date, p_end_date)),
      'total_expenses', (SELECT total_expenses FROM public.get_cash_flow(p_tenant, p_start_date, p_end_date)),
      'net_flow', (SELECT net_cash_flow FROM public.get_cash_flow(p_tenant, p_start_date, p_end_date))
    ))
  UNION ALL
  SELECT
    'receivable_aging'::TEXT,
    jsonb_agg(jsonb_build_object(
      'customer_name', c.name,
      'amount_due', ar.amount,
      'due_date', ar.due_date,
      'days_overdue', EXTRACT(DAY FROM NOW() - ar.due_date)::INT
    ))
  FROM public.accounts_receivable ar
  JOIN public.customers c ON ar.customer_id = c.id
  WHERE ar.tenant_id = p_tenant AND ar.status IN ('pendente', 'vencido')
  UNION ALL
  SELECT
    'payable_aging'::TEXT,
    jsonb_agg(jsonb_build_object(
      'vendor_name', ap.vendor_name,
      'amount_due', ap.amount,
      'due_date', ap.due_date,
      'days_overdue', EXTRACT(DAY FROM NOW() - ap.due_date)::INT
    ))
  FROM public.accounts_payable ap
  WHERE ap.tenant_id = p_tenant AND ap.status = 'pendente';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
