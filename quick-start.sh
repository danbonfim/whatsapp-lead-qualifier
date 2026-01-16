#!/bin/bash

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
clear
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║   🚀 TRACTION X - Agente de Qualificação WhatsApp 🚀    ║"
echo "║                                                           ║"
echo "║   Setup Automático v1.0                                   ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Verificar se Docker está instalado
echo -e "${YELLOW}[1/8] Verificando Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker não encontrado!${NC}"
    echo "Instale o Docker: https://docs.docker.com/get-docker/"
    exit 1
fi
echo -e "${GREEN}✓ Docker encontrado!${NC}"

# Verificar se Docker Compose está instalado
echo -e "${YELLOW}[2/8] Verificando Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}✗ Docker Compose não encontrado!${NC}"
    echo "Instale o Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi
echo -e "${GREEN}✓ Docker Compose encontrado!${NC}"

# Criar diretórios necessários
echo -e "${YELLOW}[3/8] Criando estrutura de diretórios...${NC}"
mkdir -p scripts
mkdir -p n8n/workflows
mkdir -p supabase
mkdir -p backups
chmod +x scripts/init-databases.sh 2>/dev/null || true
echo -e "${GREEN}✓ Diretórios criados!${NC}"

# Verificar se .env existe
echo -e "${YELLOW}[4/8] Configurando variáveis de ambiente...${NC}"
if [ ! -f .env ]; then
    echo -e "${YELLOW}Arquivo .env não encontrado. Criando a partir do template...${NC}"
    
    # Gerar chaves aleatórias
    EVOLUTION_KEY=$(openssl rand -hex 32)
    N8N_PASS=$(openssl rand -base64 16)
    SUPABASE_PASS=$(openssl rand -base64 16)
    
    cat > .env << EOF
# Evolution API
EVOLUTION_API_KEY=${EVOLUTION_KEY}
EVOLUTION_INSTANCE=traction-leads

# N8N
N8N_USER=admin
N8N_PASSWORD=${N8N_PASS}
N8N_WEBHOOK_URL=http://n8n:5678/webhook

# Supabase
SUPABASE_DB_PASSWORD=${SUPABASE_PASS}
SUPABASE_URL=http://localhost:8000
SUPABASE_ANON_KEY=SEU_ANON_KEY_AQUI
SUPABASE_SERVICE_KEY=SEU_SERVICE_KEY_AQUI

# Anthropic Claude API (OBRIGATÓRIO)
ANTHROPIC_API_KEY=sk-ant-COLOQUE_SUA_KEY_AQUI

# HubSpot (OBRIGATÓRIO)
HUBSPOT_API_KEY=pat-na1-COLOQUE_SUA_KEY_AQUI

# Telegram Bot (OBRIGATÓRIO)
TELEGRAM_BOT_TOKEN=1234567890:COLOQUE_SEU_TOKEN_AQUI
TELEGRAM_SALES_CHAT_ID=-100COLOQUE_SEU_CHAT_ID_AQUI

# PostgreSQL
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres

# Timezone
TZ=America/Sao_Paulo
EOF

    echo -e "${GREEN}✓ Arquivo .env criado!${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  IMPORTANTE: Configure as seguintes chaves no arquivo .env:${NC}"
    echo -e "   ${BLUE}→${NC} ANTHROPIC_API_KEY (obtenha em: https://console.anthropic.com)"
    echo -e "   ${BLUE}→${NC} HUBSPOT_API_KEY (obtenha em: https://app.hubspot.com)"
    echo -e "   ${BLUE}→${NC} TELEGRAM_BOT_TOKEN (obtenha com @BotFather)"
    echo -e "   ${BLUE}→${NC} TELEGRAM_SALES_CHAT_ID"
    echo ""
    read -p "Pressione ENTER para editar o .env agora ou CTRL+C para sair..."
    
    # Tentar abrir editor
    if command -v nano &> /dev/null; then
        nano .env
    elif command -v vim &> /dev/null; then
        vim .env
    elif command -v vi &> /dev/null; then
        vi .env
    else
        echo -e "${YELLOW}Abra o arquivo .env manualmente e configure as chaves!${NC}"
        exit 0
    fi
else
    echo -e "${GREEN}✓ Arquivo .env encontrado!${NC}"
fi

# Validar configurações mínimas
echo -e "${YELLOW}[5/8] Validando configurações...${NC}"
source .env

if [ "$ANTHROPIC_API_KEY" = "sk-ant-COLOQUE_SUA_KEY_AQUI" ]; then
    echo -e "${RED}✗ Configure a ANTHROPIC_API_KEY no arquivo .env!${NC}"
    exit 1
fi

if [ "$HUBSPOT_API_KEY" = "pat-na1-COLOQUE_SUA_KEY_AQUI" ]; then
    echo -e "${YELLOW}⚠️  HubSpot API Key não configurada. Configure depois no N8N.${NC}"
fi

if [ "$TELEGRAM_BOT_TOKEN" = "1234567890:COLOQUE_SEU_TOKEN_AQUI" ]; then
    echo -e "${YELLOW}⚠️  Telegram Bot Token não configurado. Configure depois no N8N.${NC}"
fi

echo -e "${GREEN}✓ Configurações validadas!${NC}"

# Baixar imagens Docker
echo -e "${YELLOW}[6/8] Baixando imagens Docker (isso pode demorar)...${NC}"
docker-compose pull
echo -e "${GREEN}✓ Imagens baixadas!${NC}"

# Iniciar containers
echo -e "${YELLOW}[7/8] Iniciando containers...${NC}"
docker-compose up -d
echo -e "${GREEN}✓ Containers iniciados!${NC}"

# Aguardar serviços ficarem prontos
echo -e "${YELLOW}[8/8] Aguardando serviços ficarem prontos...${NC}"
sleep 10

# Verificar status
echo ""
echo -e "${GREEN}✓✓✓ INSTALAÇÃO CONCLUÍDA! ✓✓✓${NC}"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}URLs de Acesso:${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${YELLOW}Evolution API (WhatsApp):${NC}"
echo -e "    → http://localhost:8080"
echo -e "    → Usuário: (não requer login)"
echo ""
echo -e "  ${YELLOW}N8N (Automação):${NC}"
echo -e "    → http://localhost:5678"
echo -e "    → Usuário: ${GREEN}admin${NC}"
echo -e "    → Senha: ${GREEN}${N8N_PASSWORD}${NC}"
echo ""
echo -e "  ${YELLOW}Supabase Studio (Database):${NC}"
echo -e "    → http://localhost:54323"
echo ""
echo -e "  ${YELLOW}Portainer (Gerenciamento):${NC}"
echo -e "    → http://localhost:9000"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Próximos Passos:${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${YELLOW}1.${NC} Conectar WhatsApp:"
echo -e "     → Acesse: http://localhost:8080/manager"
echo -e "     → Crie instância: ${GREEN}traction-leads${NC}"
echo -e "     → Escaneie QR Code"
echo ""
echo -e "  ${YELLOW}2.${NC} Configurar N8N:"
echo -e "     → Acesse: http://localhost:5678"
echo -e "     → Login: admin / ${GREEN}${N8N_PASSWORD}${NC}"
echo -e "     → Importe o workflow"
echo -e "     → Configure credenciais (Supabase, HubSpot, Telegram)"
echo ""
echo -e "  ${YELLOW}3.${NC} Testar:"
echo -e "     → Envie mensagem para o WhatsApp conectado"
echo -e "     → Verifique resposta do agente"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}Comandos úteis:${NC}"
echo -e "  ${BLUE}→${NC} Ver logs:        ${YELLOW}docker-compose logs -f${NC}"
echo -e "  ${BLUE}→${NC} Status:          ${YELLOW}docker-compose ps${NC}"
echo -e "  ${BLUE}→${NC} Parar:           ${YELLOW}docker-compose stop${NC}"
echo -e "  ${BLUE}→${NC} Reiniciar:       ${YELLOW}docker-compose restart${NC}"
echo -e "  ${BLUE}→${NC} Backup DB:       ${YELLOW}make backup${NC}"
echo -e "  ${BLUE}→${NC} Stats de leads:  ${YELLOW}make stats${NC}"
echo ""
echo -e "${GREEN}Documentação completa:${NC} README.md"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}🎉 Seu agente de qualificação está pronto! 🎉${NC}"
echo ""

# Salvar credenciais em arquivo
cat > CREDENTIALS.txt << EOF
═══════════════════════════════════════════
CREDENCIAIS DO SISTEMA - TRACTION X
═══════════════════════════════════════════

N8N:
  URL: http://localhost:5678
  Usuário: admin
  Senha: ${N8N_PASSWORD}

Evolution API:
  URL: http://localhost:8080
  API Key: ${EVOLUTION_KEY}

PostgreSQL:
  Host: localhost:5432
  User: postgres
  Password: postgres

Supabase:
  URL: http://localhost:8000
  Studio: http://localhost:54323
  Password: ${SUPABASE_PASS}

═══════════════════════════════════════════
GUARDE ESTE ARQUIVO EM LOCAL SEGURO!
═══════════════════════════════════════════
EOF

echo -e "${YELLOW}💾 Credenciais salvas em: ${GREEN}CREDENTIALS.txt${NC}"
echo ""
