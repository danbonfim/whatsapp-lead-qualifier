# 📦 Arquivos do Projeto - Artifacts

## 📌 Importante!

Todos os arquivos de configuração deste projeto estão disponíveis como **artifacts** na conversa do Claude onde o projeto foi criado.

🔗 **Link da Conversa do Claude**: https://claude.ai/chat/3c086c14-072f-459c-b4db-da60bcfbe346

---

## 📄 Arquivos Disponíveis nos Artifacts

Na conversa do Claude acima, você encontrará os seguintes arquivos prontos para uso:

### 🐳 Docker & Infrastructure
- **`docker-compose.yml`** - Stack completa com todos os serviços
  - Evolution API (WhatsApp Gateway)
  - N8N (Automação)
  - PostgreSQL (Banco de dados)
  - Supabase (Interface + API)
  - Redis (Cache)
  - Portainer (Gerenciamento Docker)

### ⚙️ Configuration
- **`.env.example`** - Template de variáveis de ambiente
  - API Keys (Anthropic, HubSpot, Telegram)
  - Configurações de banco de dados
  - URLs e portas dos serviços

### 🚀 Scripts
- **`quick-start.sh`** - Script de instalação automática
  - Verifica dependências
  - Cria estrutura de diretórios
  - Gera chaves seguras
  - Inicializa todos os serviços

- **`scripts/init-databases.sh`** - Script de inicialização do PostgreSQL
  - Cria databases: evolution, n8n, supabase
  - Configura permissões

### 🛠️ Makefile
- **`Makefile`** - Comandos úteis para gerenciamento
  - `make start`, `make stop`, `make restart`
  - `make logs`, `make status`, `make health`
  - `make backup`, `make stats`
  - `make export-leads`

### 📊 Database
- **`supabase/init.sql`** - Schema completo do Supabase
  - Tabelas: `leads`, `messages`, `lead_metrics`, `campaigns`
  - Triggers automáticos
  - Views materializadas
  - Functions SQL úteis
  - Indexes otimizados

### 🤖 N8N Workflow
- **`n8n/workflows/lead-qualifier.json`** - Workflow N8N pronto
  - Recepção de mensagens WhatsApp
  - Integração com Claude AI
  - Qualificação automática de leads
  - Integração HubSpot
  - Notificações Telegram

### 📚 Documentação
- **`INSTALL.md`** - Guia completo de instalação
  - Método 1: Instalação Automática (5 min)
  - Método 2: Instalação Manual (15 min)
  - Método 3: Deploy em Produção (VPS/Cloud)
  - Troubleshooting completo

---

## 💻 Como Usar os Artifacts

### Opção 1: Copiar Manualmente

1. **Acesse a conversa do Claude**: https://claude.ai/chat/3c086c14-072f-459c-b4db-da60bcfbe346

2. **Localize os artifacts**: Role a conversa e procure pelos blocos com títulos como:
   - "docker-compose.yml - Stack Completa"
   - ".env.example - Variáveis de Ambiente"
   - etc.

3. **Copie cada artifact**:
   - Clique no botão "Copiar" no canto superior direito de cada artifact
   - Cole o conteúdo no arquivo correspondente no seu projeto

4. **Crie a estrutura de diretórios**:
   ```bash
   mkdir -p scripts supabase n8n/workflows
   ```

5. **Salve cada arquivo** no local correto conforme a estrutura do projeto

### Opção 2: Clone e Configure

1. **Clone este repositório**:
   ```bash
   git clone https://github.com/danbonfim/whatsapp-lead-qualifier.git
   cd whatsapp-lead-qualifier
   ```

2. **Acesse os artifacts no Claude** e copie os arquivos necessários

3. **Configure o .env**:
   ```bash
   cp .env.example .env
   # Edite o .env com suas API Keys
   ```

4. **Execute o instalador**:
   ```bash
   chmod +x quick-start.sh
   ./quick-start.sh
   ```

---

## 🗒️ Estrutura Completa do Projeto

Depois de copiar todos os artifacts, sua estrutura ficará assim:

```
whatsapp-lead-qualifier/
├── .gitignore                   # Arquivos ignorados pelo Git
├── README.md                    # Documentação principal (já criado)
├── ARTIFACTS.md                 # Este arquivo
├── INSTALL.md                   # Guia de instalação completo
├── docker-compose.yml           # Stack completa
├── .env.example                 # Template de variáveis
├── .env                         # Suas variáveis (criar manualmente)
├── Makefile                     # Comandos úteis
├── quick-start.sh              # Script de instalação automática
├── scripts/
│   └── init-databases.sh       # Inicialização do PostgreSQL
├── supabase/
│   └── init.sql                # Schema completo do banco
└── n8n/
    └── workflows/
        └── lead-qualifier.json  # Workflow N8N pronto
```

---

## ❗ Arquivos que Você Precisa Criar Manualmente

### `.env` (baseado no `.env.example`)

Depois de copiar o `.env.example`, crie seu `.env` com suas credenciais reais:

```bash
# APIs Externas (OBRIGATÓRIAS)
ANTHROPIC_API_KEY=sk-ant-sua-chave-real-aqui
HUBSPOT_API_KEY=pat-na1-sua-chave-real-aqui
TELEGRAM_BOT_TOKEN=1234567890:ABCdefGHIjklMNOpqrsTUVwxyz
TELEGRAM_SALES_CHAT_ID=-1001234567890

# Evolution API (o script quick-start.sh pode gerar automaticamente)
EVOLUTION_API_KEY=chave_segura_gerada_automaticamente
EVOLUTION_INSTANCE=traction-leads

# Database
POSTGRES_USER=postgres
POSTGRES_PASSWORD=senha_segura_aqui
```

---

## 🔗 Links Úteis

- **Conversa do Claude (Artifacts)**: https://claude.ai/chat/3c086c14-072f-459c-b4db-da60bcfbe346
- **Repositório GitHub**: https://github.com/danbonfim/whatsapp-lead-qualifier
- **TRACTION X**: https://tractiongrowthx.lovable.app
- **LinkedIn do Criador**: https://linkedin.com/in/danbonfim

---

## 💬 Suporte

Para dúvidas sobre como usar os artifacts ou configurar o projeto:

1. Consulte o **INSTALL.md** (disponível nos artifacts do Claude)
2. Veja o **README.md** deste repositório
3. Entre em contato via LinkedIn: https://linkedin.com/in/danbonfim

---

**🚀 Desenvolvido com ❤️ para revolucionar a qualificação de leads B2B**
