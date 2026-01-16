-- ====================================
-- SCHEMA SUPABASE - LEAD QUALIFIER
-- ====================================

-- Criar schema
CREATE SCHEMA IF NOT EXISTS public;

-- Tabela principal de leads
CREATE TABLE IF NOT EXISTS public.leads (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  whatsapp_number VARCHAR(20) UNIQUE NOT NULL,
  status VARCHAR(50) DEFAULT 'novo' CHECK (status IN ('novo', 'em_qualificacao', 'qualificado', 'nutrir', 'desqualificado')),
  lead_score INTEGER DEFAULT 0 CHECK (lead_score >= 0 AND lead_score <= 100),
  
  -- Dados pessoais
  nome VARCHAR(255),
  cargo VARCHAR(255),
  email VARCHAR(255),
  
  -- Dados da empresa
  empresa VARCHAR(255),
  tamanho_time VARCHAR(50),
  faturamento_range VARCHAR(50),
  
  -- Qualificação
  desafio_principal TEXT,
  tem_sdr BOOLEAN DEFAULT false,
  decisor BOOLEAN DEFAULT false,
  
  -- Integrações
  hubspot_contact_id VARCHAR(50),
  hubspot_deal_id VARCHAR(50),
  
  -- Conversação
  conversation_history JSONB DEFAULT '[]'::jsonb,
  last_message_at TIMESTAMP WITH TIME ZONE,
  messages_count INTEGER DEFAULT 0,
  
  -- Análise
  sentiment_score DECIMAL(3,2), -- -1.0 a 1.0
  engagement_level VARCHAR(20), -- baixo, medio, alto
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  qualified_at TIMESTAMP WITH TIME ZONE,
  disqualified_at TIMESTAMP WITH TIME ZONE
);

-- Tabela de métricas e analytics
CREATE TABLE IF NOT EXISTS public.lead_metrics (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  lead_id UUID REFERENCES public.leads(id) ON DELETE CASCADE,
  
  -- Métricas de tempo
  time_to_qualify_minutes INTEGER,
  time_to_respond_seconds INTEGER,
  
  -- Métricas de engajamento
  total_messages_sent INTEGER DEFAULT 0,
  total_messages_received INTEGER DEFAULT 0,
  avg_response_time_seconds INTEGER,
  
  -- Qualidade
  qualification_attempt INTEGER DEFAULT 1,
  objections_raised INTEGER DEFAULT 0,
  
  -- Resultados
  qualified_successfully BOOLEAN DEFAULT false,
  disqualification_reason TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de mensagens (histórico detalhado)
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  lead_id UUID REFERENCES public.leads(id) ON DELETE CASCADE,
  
  role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
  content TEXT NOT NULL,
  
  -- Metadata
  message_type VARCHAR(50), -- text, image, audio, document
  tokens_used INTEGER,
  ai_model VARCHAR(50),
  
  -- Análise
  sentiment VARCHAR(20), -- positive, negative, neutral
  extracted_intent VARCHAR(100),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de campanhas (para A/B testing futuro)
CREATE TABLE IF NOT EXISTS public.campaigns (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  
  -- Configurações
  prompt_variant TEXT,
  qualification_criteria JSONB,
  
  -- Métricas
  leads_count INTEGER DEFAULT 0,
  qualified_count INTEGER DEFAULT 0,
  conversion_rate DECIMAL(5,2),
  
  is_active BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ====================================
-- ÍNDICES PARA PERFORMANCE
-- ====================================

CREATE INDEX idx_leads_whatsapp ON public.leads(whatsapp_number);
CREATE INDEX idx_leads_status ON public.leads(status);
CREATE INDEX idx_leads_score ON public.leads(lead_score DESC);
CREATE INDEX idx_leads_created ON public.leads(created_at DESC);
CREATE INDEX idx_leads_qualified ON public.leads(qualified_at DESC) WHERE qualified_at IS NOT NULL;
CREATE INDEX idx_leads_empresa ON public.leads(empresa);

CREATE INDEX idx_messages_lead ON public.messages(lead_id);
CREATE INDEX idx_messages_created ON public.messages(created_at DESC);

CREATE INDEX idx_metrics_lead ON public.lead_metrics(lead_id);

-- Índice GIN para busca em JSONB
CREATE INDEX idx_leads_conversation_history ON public.leads USING GIN (conversation_history);

-- ====================================
-- TRIGGERS E FUNCTIONS
-- ====================================

-- Function: Atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_leads_updated_at 
BEFORE UPDATE ON public.leads
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_campaigns_updated_at 
BEFORE UPDATE ON public.campaigns
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function: Marcar qualified_at quando status muda para 'qualificado'
CREATE OR REPLACE FUNCTION set_qualified_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'qualificado' AND (OLD.status IS NULL OR OLD.status != 'qualificado') THEN
        NEW.qualified_at = NOW();
    ELSIF NEW.status = 'desqualificado' AND (OLD.status IS NULL OR OLD.status != 'desqualificado') THEN
        NEW.disqualified_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_leads_qualified_timestamp 
BEFORE UPDATE ON public.leads
FOR EACH ROW EXECUTE FUNCTION set_qualified_timestamp();

-- Function: Atualizar contador de mensagens
CREATE OR REPLACE FUNCTION update_message_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.leads 
    SET 
        messages_count = messages_count + 1,
        last_message_at = NEW.created_at
    WHERE id = NEW.lead_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER increment_message_count 
AFTER INSERT ON public.messages
FOR EACH ROW EXECUTE FUNCTION update_message_count();

-- Function: Calcular métricas quando lead é qualificado
CREATE OR REPLACE FUNCTION calculate_lead_metrics()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'qualificado' AND OLD.status != 'qualificado' THEN
        INSERT INTO public.lead_metrics (
            lead_id,
            time_to_qualify_minutes,
            total_messages_sent,
            total_messages_received,
            qualified_successfully
        )
        SELECT 
            NEW.id,
            EXTRACT(EPOCH FROM (NOW() - NEW.created_at))/60,
            (SELECT COUNT(*) FROM public.messages WHERE lead_id = NEW.id AND role = 'assistant'),
            (SELECT COUNT(*) FROM public.messages WHERE lead_id = NEW.id AND role = 'user'),
            true;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_metrics_on_qualification 
AFTER UPDATE ON public.leads
FOR EACH ROW EXECUTE FUNCTION calculate_lead_metrics();

-- ====================================
-- VIEWS ÚTEIS
-- ====================================

-- View: Dashboard de conversão
CREATE OR REPLACE VIEW public.conversion_dashboard AS
SELECT 
    DATE(created_at) as data,
    COUNT(*) as total_leads,
    COUNT(*) FILTER (WHERE status = 'qualificado') as qualificados,
    COUNT(*) FILTER (WHERE status = 'desqualificado') as desqualificados,
    COUNT(*) FILTER (WHERE status IN ('novo', 'em_qualificacao')) as em_processo,
    ROUND(AVG(lead_score), 2) as score_medio,
    ROUND(
        COUNT(*) FILTER (WHERE status = 'qualificado')::DECIMAL / 
        NULLIF(COUNT(*), 0) * 100, 
        2
    ) as taxa_conversao
FROM public.leads
GROUP BY DATE(created_at)
ORDER BY data DESC;

-- View: Performance por empresa
CREATE OR REPLACE VIEW public.empresa_performance AS
SELECT 
    empresa,
    COUNT(*) as total_leads,
    COUNT(*) FILTER (WHERE status = 'qualificado') as qualificados,
    ROUND(AVG(lead_score), 2) as score_medio,
    MAX(qualified_at) as ultima_qualificacao
FROM public.leads
WHERE empresa IS NOT NULL
GROUP BY empresa
ORDER BY qualificados DESC, score_medio DESC;

-- View: Leads hot (alta pontuação e recentes)
CREATE OR REPLACE VIEW public.hot_leads AS
SELECT 
    id,
    nome,
    empresa,
    whatsapp_number,
    lead_score,
    status,
    desafio_principal,
    created_at
FROM public.leads
WHERE 
    status IN ('em_qualificacao', 'novo')
    AND lead_score >= 60
    AND created_at > NOW() - INTERVAL '7 days'
ORDER BY lead_score DESC, created_at DESC;

-- ====================================
-- ROW LEVEL SECURITY (RLS)
-- ====================================

ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lead_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;

-- Policy: Service role tem acesso total
CREATE POLICY "Service role full access - leads" ON public.leads
  FOR ALL
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Service role full access - messages" ON public.messages
  FOR ALL
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Service role full access - metrics" ON public.lead_metrics
  FOR ALL
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Service role full access - campaigns" ON public.campaigns
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- ====================================
-- DADOS INICIAIS
-- ====================================

-- Campanha padrão
INSERT INTO public.campaigns (name, description, is_active)
VALUES ('Default Campaign', 'Campanha padrão de qualificação via WhatsApp', true)
ON CONFLICT DO NOTHING;

-- ====================================
-- FUNÇÕES ÚTEIS PARA REPORTS
-- ====================================

-- Function: Obter estatísticas do dia
CREATE OR REPLACE FUNCTION get_daily_stats()
RETURNS TABLE (
    leads_hoje INTEGER,
    qualificados_hoje INTEGER,
    taxa_conversao_hoje DECIMAL,
    score_medio_hoje DECIMAL,
    tempo_medio_qualificacao_min INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as leads_hoje,
        COUNT(*) FILTER (WHERE status = 'qualificado')::INTEGER as qualificados_hoje,
        ROUND(
            COUNT(*) FILTER (WHERE status = 'qualificado')::DECIMAL / 
            NULLIF(COUNT(*), 0) * 100, 
            2
        ) as taxa_conversao_hoje,
        ROUND(AVG(lead_score), 2) as score_medio_hoje,
        (SELECT ROUND(AVG(time_to_qualify_minutes))::INTEGER 
         FROM public.lead_metrics 
         WHERE DATE(created_at) = CURRENT_DATE) as tempo_medio_qualificacao_min
    FROM public.leads
    WHERE DATE(created_at) = CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;

-- Function: Top desafios mencionados
CREATE OR REPLACE FUNCTION get_top_challenges(limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
    desafio TEXT,
    count_leads BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        desafio_principal,
        COUNT(*) as count_leads
    FROM public.leads
    WHERE 
        desafio_principal IS NOT NULL 
        AND desafio_principal != ''
    GROUP BY desafio_principal
    ORDER BY count_leads DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON TABLE public.leads IS 'Tabela principal de leads capturados via WhatsApp';
COMMENT ON TABLE public.messages IS 'Histórico detalhado de todas as mensagens trocadas';
COMMENT ON TABLE public.lead_metrics IS 'Métricas de performance e qualidade da qualificação';
COMMENT ON TABLE public.campaigns IS 'Campanhas e variantes de prompts para A/B testing';
