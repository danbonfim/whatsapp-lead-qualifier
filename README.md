# 🚀 Agente de Qualificação de Leads via WhatsApp - TRACTION X

Sistema completo de qualificação automatizada de leads B2B via WhatsApp usando metodologias **Challenger Sale** e **Receita Previsível (2026)**.

## 🎯 Características Principais

### Metodologias Implementadas
- **Challenger Sale**: Ensinar insights, adaptar mensagens, controlar a conversa
- **Receita Previsível**: Qualificação rigorosa (Cold Call 2.0), separação SDR/Closer
- **Claude Sonnet 4**: IA para conversas naturais e qualificação inteligente

### Stack 100% Gratuita (Exceto Claude API)
- **Evolution API**: WhatsApp Gateway open-source
- **N8N**: Automação de workflows (free tier: 5k execuções/mês)
- **Supabase**: Database PostgreSQL (free tier: 500MB, 50k requests/mês)
- **Claude API**: Pay-as-you-go (~R$0,15 por conversa)
- **HubSpot Free**: CRM completo
- **Telegram**: Notificações gratuitas

**Custo estimado**: R$ 50-150/mês (principalmente Claude API)

## 📦 Componentes

1. **Evolution API** (porta 8080) - Gateway WhatsApp
2. **N8N** (porta 5678) - Automação e workflows
3. **PostgreSQL** (porta 5432) - Banco de dados principal
4. **Supabase** (porta 54323) - Interface de gerenciamento
5. **Redis** (porta 6379) - Cache para performance
6. **Portainer** (porta 9000) - Gerenciamento Docker

## 🚀 Instalação Rápida

### Requisitos
- Docker 20.10+
- Docker Compose 2.0+
- 2GB RAM disponível
- 10GB espaço em disco

### Método 1: Instalação Automática (5 minutos) ⭐ RECOMENDADO

```bash
# 1. Clone o repositório
git clone https://github.com/danbonfim/whatsapp-lead-qualifier.git
cd whatsapp-lead-qualifier

# 2. Execute o instalador
chmod +x quick-start.sh
./quick-start.sh

# 3. Configure as API Keys quando solicitado
# - Anthropic API Key (obrigatória)
# - HubSpot API Key (recomendada)
# - Telegram Bot Token (opcional)
```

O script irá:
- ✅ Verificar dependências
- ✅ Criar estrutura de diretórios  
- ✅ Gerar .env com chaves seguras
- ✅ Baixar e iniciar todos os serviços
- ✅ Mostrar URLs e credenciais de acesso

### Método 2: Docker Compose Manual

```bash
cp .env.example .env
# Edite o .env com suas chaves
docker-compose up -d
```

## 🔑 Configuração

### Obtenha suas API Keys:

1. **Anthropic (Claude)** - Obrigatória
   - Acesse: https://console.anthropic.com
   - Crie API Key em Settings
   - Custo: ~R$0,15 por conversa qualificada

2. **HubSpot** - Recomendada  
   - Acesse: https://app.hubspot.com
   - Settings → Integrations → Private Apps
   - Free tier funciona perfeitamente

3. **Telegram** - Opcional
   - Fale com @BotFather no Telegram
   - Use /newbot para criar seu bot
   - Para notificações do time de vendas

### Configure o .env:

```bash
# APIs Externas (obrigatórias)
ANTHROPIC_API_KEY=sk-ant-sua-chave-aqui
HUBSPOT_API_KEY=pat-na1-sua-chave-aqui
TELEGRAM_BOT_TOKEN=seu-token-aqui
TELEGRAM_SALES_CHAT_ID=-100seu-chat-id

# Evolution API (geradas automaticamente pelo script)
EVOLUTION_API_KEY=chave_gerada_automaticamente
EVOLUTION_INSTANCE=traction-leads
```

## 🎯 Funcionalidades

### Qualificação Inteligente
- ✅ Framework Challenger Sale (Ensinar, Adaptar, Controlar)
- ✅ Metodologia Receita Previsível (Cold Call 2.0)
- ✅ Score automático 0-100
- ✅ Categorização: qualificado/nutrir/desqualificado
- ✅ Histórico completo de conversas

### Integrações
- ✅ HubSpot - Cria contato + deal automaticamente
- ✅ Telegram - Notifica time em tempo real
- ✅ Supabase - Armazena todas as interações
- ✅ Webhooks customizados

### Analytics
- ✅ Dashboard SQL com queries prontas
- ✅ Views materializadas
- ✅ Métricas de performance
- ✅ Exportação CSV

## 📊 Uso

### 1. Conectar WhatsApp

```bash
# Acesse Evolution API
open http://localhost:8080

# Crie instância "traction-leads"
# Escaneie QR Code com seu WhatsApp Business
```

### 2. Importar Workflow N8N

```bash
# Acesse N8N
open http://localhost:5678

# Importe o arquivo n8n/workflows/lead-qualifier.json
# Configure credenciais (Supabase, HubSpot, Telegram)
# Ative o workflow
```

### 3. Testar

Envie uma mensagem para o WhatsApp conectado:
```
Oi, gostaria de conhecer a TRACTION X
```

O agente deve responder com abordagem Challenger Sale.

## 📚 Comandos Úteis

Se você usou o instalador automático, os seguintes comandos estão disponíveis:

```bash
make start          # Iniciar todos os containers
make stop           # Parar todos os containers
make restart        # Reiniciar
make logs           # Ver logs em tempo real
make status         # Status dos containers
make health         # Health check
make backup         # Backup do banco de dados
make stats          # Estatísticas de leads
make export-leads   # Exportar leads para CSV
make clean          # Limpar tudo (cuidado!)
```

## 🗂️ Estrutura do Projeto

```
whatsapp-lead-qualifier/
├── docker-compose.yml           # Stack completa
├── .env.example                 # Template de variáveis
├── .gitignore                   # Arquivos ignorados  
├── Makefile                     # Comandos úteis
├── quick-start.sh              # Script de instalação automática
├── README.md                    # Este arquivo
├── INSTALL.md                   # Guia de instalação completo
├── scripts/
│   └── init-databases.sh       # Inicialização do DB
├── supabase/
│   └── init.sql                # Schema completo
└── n8n/
    └── workflows/
        └── lead-qualifier.json  # Workflow N8N pronto
```

## 🔧 Troubleshooting

### Containers não iniciam
```bash
docker-compose logs
docker-compose down
docker-compose up -d --force-recreate
```

### Evolution API não conecta WhatsApp
- Verifique se a instância foi criada
- Tente reescanear o QR Code
- Confira logs: `docker-compose logs evolution-api`

### N8N não recebe mensagens
- Verifique webhook no Evolution
- Confirme que o workflow está ativado
- Teste manualmente o endpoint

### Claude não responde
- Verifique API Key no .env
- Confirme créditos na conta Anthropic
- Veja logs do N8N

## 📖 Documentação Completa

- **README.md** (este arquivo) - Visão geral e quick start
- **INSTALL.md** - Guia completo de instalação
- **Claude Conversation** - https://claude.ai/chat/3c086c14-072f-459c-b4db-da60bcfbe346

Todos os arquivos de configuração (docker-compose.yml, scripts, schemas SQL) estão disponíveis na conversa do Claude acima como artifacts.

## 💡 Próximos Passos

1. ⚡ Execute o quick-start.sh
2. 🔑 Configure as API Keys
3. 📱 Conecte seu WhatsApp  
4. 🤖 Importe o workflow N8N
5. 🧪 Teste com leads reais
6. 📊 Acompanhe métricas no Supabase
7. 🎨 Personalize o prompt do Claude

## 🤝 Contribuindo

Este projeto foi criado para a TRACTION X. Sinta-se livre para fazer fork e adaptar para seu negócio.

## 📝 Licença

MIT License - Veja LICENSE para detalhes.

## 🙋 Suporte

Para dúvidas e suporte:
- 📧 Email: [seu-email]
- 💼 LinkedIn: https://linkedin.com/in/danbonfim
- 🌐 Site: https://tractiongrowthx.lovable.app

---

**Desenvolvido com ❤️ para revolucionar a qualificação de leads B2B**
