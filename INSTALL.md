# 📦 Guia de Instalação Completo

Este guia cobre três métodos de instalação:
1. **Instalação Automática** (Recomendado - 5 minutos)
2. **Instalação Manual** (Controle total - 15 minutos)
3. **Instalação em Produção** (Deploy em servidor)

---

## 🚀 Método 1: Instalação Automática (Recomendado)

### Requisitos

- Docker 20.10+
- Docker Compose 2.0+
- 2GB RAM disponível
- 10GB espaço em disco

### Passo a Passo

#### 1. Clone o repositório

```bash
git clone https://github.com/seu-usuario/whatsapp-lead-qualifier.git
cd whatsapp-lead-qualifier
```

#### 2. Execute o instalador

```bash
chmod +x quick-start.sh
./quick-start.sh
```

O script irá:
- ✅ Verificar dependências
- ✅ Criar estrutura de diretórios
- ✅ Gerar arquivo .env com chaves seguras
- ✅ Baixar imagens Docker
- ✅ Iniciar todos os serviços
- ✅ Mostrar URLs e credenciais

#### 3. Configure as API Keys

O script vai pausar para você editar o `.env`. Configure:

```bash
# Obrigatórias:
ANTHROPIC_API_KEY=sk-ant-sua-chave-aqui
HUBSPOT_API_KEY=pat-na1-sua-chave-aqui
TELEGRAM_BOT_TOKEN=seu-token-aqui
TELEGRAM_SALES_CHAT_ID=-100seu-chat-id
```

**Onde obter as chaves:**

- **Anthropic**: https://console.anthropic.com → API Keys
- **HubSpot**: https://app.hubspot.com → Settings → Integrations → Private Apps
- **Telegram**: Fale com @BotFather no Telegram

#### 4. Pronto! 🎉

Acesse as interfaces:
- Evolution API: http://localhost:8080
- N8N: http://localhost:5678
- Supabase: http://localhost:54323

---

## ⚙️ Método 2: Instalação Manual

### 1. Prepare o ambiente

```bash
# Clone
git clone https://github.com/seu-usuario/whatsapp-lead-qualifier.git
cd whatsapp-lead-qualifier

# Estrutura
mkdir -p scripts supabase n8n/workflows backups

# Permissões
chmod +x scripts/init-databases.sh
```

### 2. Configure .env

```bash
cp .env.example .env
nano .env  # ou seu editor preferido
```

Preencha TODAS as variáveis:

```bash
# Evolution API
EVOLUTION_API_KEY=gere_chave_aleatoria_32_chars
EVOLUTION_INSTANCE=traction-leads

# N8N
N8N_USER=admin
N8N_PASSWORD=senha_forte_aqui
N8N_WEBHOOK_URL=http://n8n:5678/webhook

# Supabase
SUPABASE_DB_PASSWORD=senha_postgres
SUPABASE_URL=http://localhost:8000
SUPABASE_ANON_KEY=seu_anon_key
SUPABASE_SERVICE_KEY=seu_service_key

# APIs Externas
ANTHROPIC_API_KEY=sk-ant-sua_chave
HUBSPOT_API_KEY=pat-na1-sua_chave
TELEGRAM_BOT_TOKEN=seu_token
TELEGRAM_SALES_CHAT_ID=-100seu_chat_id

# Database
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres

# Timezone
TZ=America/Sao_Paulo
```

### 3. Crie os arquivos necessários

#### scripts/init-databases.sh

```bash
#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE DATABASE evolution;
    CREATE DATABASE n8n;
    CREATE DATABASE supabase;
    
    GRANT ALL PRIVILEGES ON DATABASE evolution TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE n8n TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE supabase TO $POSTGRES_USER;
EOSQL
```

#### supabase/init.sql

(Use o SQL fornecido no artifact "supabase/init.sql")

### 4. Inicie os serviços

```bash
# Baixar imagens
docker-compose pull

# Iniciar
docker-compose up -d

# Verificar
docker-compose ps
```

Todos devem estar "Up".

### 5. Configure cada serviço

#### Evolution API

1. Acesse: http://localhost:8080/manager
2. Crie instância: `traction-leads`
3. Escaneie QR Code
4. Configure webhook:

```bash
curl -X POST http://localhost:8080/webhook/set/traction-leads \
  -H "apikey: sua_evolution_api_key" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "http://n8n:5678/webhook/whatsapp-webhook",
    "webhook_by_events": true,
    "events": ["messages.upsert"]
  }'
```

#### N8N

1. Acesse: http://localhost:5678
2. Login com credenciais do .env
3. Importe workflow (ver seção "Importar Workflow")
4. Configure credenciais:
   - Supabase (Service Role Key)
   - HubSpot (API Key)
   - Telegram (Bot Token)
5. Ative o workflow

#### Supabase

O schema já foi criado automaticamente. Verifique:

```bash
docker-compose exec supabase-db psql -U postgres -d supabase -c "\dt"
```

Deve mostrar as tabelas: `leads`, `messages`, `lead_metrics`, `campaigns`

---

## 🌐 Método 3: Instalação em Produção

### Opção A: VPS (Recomendado)

**Providers sugeridos:**
- DigitalOcean (Droplet $6/mês)
- Hetzner (VPS €4/mês)
- Contabo (VPS €7/mês)

**Especificações mínimas:**
- 2 vCPU
- 4GB RAM
- 40GB SSD
- Ubuntu 22.04 LTS

#### Passo a Passo

1. **SSH no servidor:**

```bash
ssh root@seu-ip
```

2. **Instale Docker:**

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
apt install docker-compose-plugin
```

3. **Clone e configure:**

```bash
cd /opt
git clone https://github.com/seu-usuario/whatsapp-lead-qualifier.git
cd whatsapp-lead-qualifier
./quick-start.sh
```

4. **Configure domínios (Nginx Reverse Proxy):**

```bash
apt install nginx certbot python3-certbot-nginx

# Criar configuração Nginx
nano /etc/nginx/sites-available/lead-qualifier
```

Arquivo Nginx:

```nginx
# Evolution API
server {
    listen 80;
    server_name whatsapp.seudominio.com;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}

# N8N
server {
    listen 80;
    server_name n8n.seudominio.com;
    
    location / {
        proxy_pass http://localhost:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

5. **Ativar SSL:**

```bash
ln -s /etc/nginx/sites-available/lead-qualifier /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx

certbot --nginx -d whatsapp.seudominio.com -d n8n.seudominio.com
```

6. **Configure firewall:**

```bash
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 22/tcp
ufw enable
```

7. **Atualize .env com URLs públicas:**

```bash
PUBLIC_N8N_URL=https://n8n.seudominio.com
PUBLIC_EVOLUTION_URL=https://whatsapp.seudominio.com
N8N_WEBHOOK_URL=https://n8n.seudominio.com/webhook
```

8. **Reinicie:**

```bash
docker-compose down
docker-compose up -d
```

### Opção B: Railway (PaaS - Mais fácil)

1. Acesse: https://railway.app
2. New Project > Deploy from GitHub
3. Conecte seu repositório
4. Railway vai detectar o docker-compose.yml
5. Configure variáveis de ambiente na interface
6. Deploy automático!

Railway fornece URLs públicas automaticamente.

### Opção C: Render (PaaS - Gratuito)

Limitações: 750h/mês gratuitas, pode hibernar após inatividade.

Similar ao Railway, mas com interface diferente.

---

## 📝 Pós-Instalação

### 1. Importar Workflow N8N

1. Acesse N8N: http://localhost:5678 (ou sua URL)
2. Menu > Workflows > Import from File
3. Selecione: `n8n/workflows/lead-qualifier.json`
4. Clique em "Import"

Se não tiver o arquivo, copie do artifact "N8N - Agente Qualificação" e salve como JSON.

### 2. Testar Sistema

```bash
# Teste webhook
make test-webhook

# Ou manualmente:
curl -X POST http://localhost:5678/webhook/whatsapp-webhook \
  -H "Content-Type: application/json" \
  -d '{
    "body": {
      "message": {
        "from": "5511999999999",
        "text": "Olá, quero saber mais sobre vocês",
        "type": "text"
      }
    }
  }'
```

### 3. Primeiro Lead de Teste

1. Envie mensagem para o WhatsApp conectado:
   ```
   Oi, gostaria de conhecer a TRACTION X
   ```

2. O agente deve responder com abordagem Challenger

3. Continue a conversa

4. Verifique:
   - Supabase: Lead registrado
   - HubSpot: Contato/deal criado (se qualificado)
   - Telegram: Notificação recebida (se qualificado)

### 4. Monitoramento

```bash
# Status dos containers
make status

# Logs em tempo real
make logs

# Estatísticas de leads
make stats

# Health check
make health
```

---

## 🔧 Troubleshooting

### Problemas Comuns

#### 1. Containers não iniciam

```bash
# Ver logs
docker-compose logs

# Recriar containers
docker-compose down
docker-compose up -d --force-recreate
```

#### 2. Evolution API não conecta WhatsApp

- Verifique se a instância foi criada corretamente
- Tente reescanear o QR Code
- Confira logs: `docker-compose logs evolution-api`

#### 3. N8N não recebe mensagens

- Verifique se o webhook está configurado no Evolution
- Teste o webhook manualmente (ver comando acima)
- Confirme que o workflow está ativado no N8N

#### 4. Claude não responde

- Verifique API Key no .env
- Confirme créditos disponíveis na conta Anthropic
- Veja logs do node HTTP Request no N8N

#### 5. Erro de permissão no PostgreSQL

```bash
# Dar permissão ao script
chmod +x scripts/init-databases.sh

# Recriar database
docker-compose down -v
docker-compose up -d
```

---

## 🔄 Atualização

### Atualizar código

```bash
git pull origin main
docker-compose down
docker-compose up -d --build
```

### Atualizar imagens Docker

```bash
make update
make restart
```

### Migração de dados

Se houver mudanças no schema:

```bash
# Backup antes
make backup

# Aplicar migrações (se houver)
docker-compose exec supabase-db psql -U postgres -d supabase < migrations/YYYYMMDD_migration.sql
```

---

## 🆘 Suporte

### Documentação

- README.md (visão geral)
- INSTALL.md (este arquivo)
- TROUBLESHOOTING.md (problemas comuns)

### Comandos Úteis

```bash
make help          # Lista todos os comandos
make dev           # Ambiente de desenvolvimento
make backup        # Backup do banco
make stats         # Estatísticas de leads
make export-leads  # Exportar leads para CSV
```

### Logs

```bash
make logs              # Todos os logs
make logs-evolution    # Apenas Evolution API
make logs-n8n          # Apenas N8N
make logs-postgres     # Apenas PostgreSQL
```

---

## ✅ Checklist de Instalação

Use este checklist para garantir que tudo está funcionando:

- [ ] Docker e Docker Compose instalados
- [ ] Repositório clonado
- [ ] Arquivo .env configurado com todas as keys
- [ ] Containers iniciados (docker-compose ps mostra todos "Up")
- [ ] Evolution API acessível (http://localhost:8080)
- [ ] WhatsApp conectado e QR Code escaneado
- [ ] N8N acessível (http://localhost:5678)
- [ ] Workflow importado no N8N
- [ ] Credenciais configuradas no N8N (Supabase, HubSpot, Telegram)
- [ ] Workflow ativado no N8N
- [ ] Webhook configurado no Evolution API
- [ ] Teste de webhook bem-sucedido
- [ ] Primeiro lead de teste funcionando
- [ ] Lead aparece no Supabase
- [ ] Notificação recebida no Telegram (se qualificado)
- [ ] Contato criado no HubSpot (se qualificado)

---

**🎉 Instalação Concluída!**

Seu agente de qualificação está pronto para trabalhar 24/7!

Para dúvidas, abra uma issue no GitHub ou consulte a documentação oficial dos componentes.
