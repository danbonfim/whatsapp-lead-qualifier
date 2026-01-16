.PHONY: help install start stop restart logs clean backup status test

# Variáveis
COMPOSE=docker-compose
BACKUP_DIR=./backups
DATE=$(shell date +%Y%m%d_%H%M%S)

# Cores para output
GREEN=\033[0;32m
YELLOW=\033[1;33m
RED=\033[0;31m
NC=\033[0m # No Color

help: ## Mostra esta ajuda
	@echo "$(GREEN)Comandos disponíveis:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'

install: ## Instala e configura o projeto
	@echo "$(GREEN)Instalando projeto...$(NC)"
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "$(YELLOW)Arquivo .env criado. Configure as variáveis antes de continuar!$(NC)"; \
		exit 1; \
	fi
	@chmod +x scripts/init-databases.sh
	@mkdir -p $(BACKUP_DIR)
	@mkdir -p n8n/workflows
	@echo "$(GREEN)✓ Projeto configurado!$(NC)"

start: ## Inicia todos os containers
	@echo "$(GREEN)Iniciando containers...$(NC)"
	$(COMPOSE) up -d
	@echo "$(GREEN)✓ Containers iniciados!$(NC)"
	@make status

stop: ## Para todos os containers
	@echo "$(YELLOW)Parando containers...$(NC)"
	$(COMPOSE) stop
	@echo "$(GREEN)✓ Containers parados!$(NC)"

restart: ## Reinicia todos os containers
	@echo "$(YELLOW)Reiniciando containers...$(NC)"
	$(COMPOSE) restart
	@echo "$(GREEN)✓ Containers reiniciados!$(NC)"

down: ## Para e remove todos os containers
	@echo "$(RED)Removendo containers...$(NC)"
	$(COMPOSE) down
	@echo "$(GREEN)✓ Containers removidos!$(NC)"

logs: ## Mostra logs de todos os containers
	$(COMPOSE) logs -f --tail=100

logs-evolution: ## Logs do Evolution API
	$(COMPOSE) logs -f evolution-api

logs-n8n: ## Logs do N8N
	$(COMPOSE) logs -f n8n

logs-postgres: ## Logs do PostgreSQL
	$(COMPOSE) logs -f postgres

status: ## Verifica status dos containers
	@echo "$(GREEN)Status dos containers:$(NC)"
	@$(COMPOSE) ps

ps: status ## Alias para status

health: ## Health check de todos os serviços
	@echo "$(GREEN)Verificando saúde dos serviços...$(NC)"
	@echo ""
	@echo "$(YELLOW)Evolution API:$(NC)"
	@curl -s http://localhost:8080 > /dev/null && echo "  $(GREEN)✓ Online$(NC)" || echo "  $(RED)✗ Offline$(NC)"
	@echo ""
	@echo "$(YELLOW)N8N:$(NC)"
	@curl -s http://localhost:5678 > /dev/null && echo "  $(GREEN)✓ Online$(NC)" || echo "  $(RED)✗ Offline$(NC)"
	@echo ""
	@echo "$(YELLOW)Supabase Studio:$(NC)"
	@curl -s http://localhost:54323 > /dev/null && echo "  $(GREEN)✓ Online$(NC)" || echo "  $(RED)✗ Offline$(NC)"
	@echo ""
	@echo "$(YELLOW)Portainer:$(NC)"
	@curl -s http://localhost:9000 > /dev/null && echo "  $(GREEN)✓ Online$(NC)" || echo "  $(RED)✗ Offline$(NC)"

backup: ## Faz backup do banco de dados
	@echo "$(GREEN)Criando backup...$(NC)"
	@mkdir -p $(BACKUP_DIR)
	@$(COMPOSE) exec -T supabase-db pg_dump -U postgres supabase > $(BACKUP_DIR)/backup_$(DATE).sql
	@echo "$(GREEN)✓ Backup criado: $(BACKUP_DIR)/backup_$(DATE).sql$(NC)"

backup-all: ## Backup completo (DB + configs)
	@echo "$(GREEN)Criando backup completo...$(NC)"
	@mkdir -p $(BACKUP_DIR)/full_$(DATE)
	@$(COMPOSE) exec -T supabase-db pg_dump -U postgres supabase > $(BACKUP_DIR)/full_$(DATE)/supabase.sql
	@$(COMPOSE) exec -T postgres pg_dump -U postgres evolution > $(BACKUP_DIR)/full_$(DATE)/evolution.sql
	@$(COMPOSE) exec -T postgres pg_dump -U postgres n8n > $(BACKUP_DIR)/full_$(DATE)/n8n.sql
	@cp .env $(BACKUP_DIR)/full_$(DATE)/.env.backup
	@tar -czf $(BACKUP_DIR)/full_backup_$(DATE).tar.gz -C $(BACKUP_DIR) full_$(DATE)
	@rm -rf $(BACKUP_DIR)/full_$(DATE)
	@echo "$(GREEN)✓ Backup completo criado: $(BACKUP_DIR)/full_backup_$(DATE).tar.gz$(NC)"

restore: ## Restaura último backup
	@echo "$(YELLOW)Restaurando último backup...$(NC)"
	@LATEST=$$(ls -t $(BACKUP_DIR)/backup_*.sql 2>/dev/null | head -1); \
	if [ -z "$$LATEST" ]; then \
		echo "$(RED)✗ Nenhum backup encontrado!$(NC)"; \
		exit 1; \
	fi; \
	echo "Restaurando: $$LATEST"; \
	$(COMPOSE) exec -T supabase-db psql -U postgres supabase < $$LATEST; \
	echo "$(GREEN)✓ Backup restaurado!$(NC)"

clean: ## Remove volumes e dados (CUIDADO!)
	@echo "$(RED)ATENÇÃO: Isso vai apagar TODOS os dados!$(NC)"
	@read -p "Tem certeza? (yes/no): " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		$(COMPOSE) down -v; \
		echo "$(GREEN)✓ Dados removidos!$(NC)"; \
	else \
		echo "$(YELLOW)Operação cancelada.$(NC)"; \
	fi

shell-evolution: ## Shell no container Evolution API
	$(COMPOSE) exec evolution-api sh

shell-n8n: ## Shell no container N8N
	$(COMPOSE) exec n8n sh

shell-db: ## Shell no PostgreSQL
	$(COMPOSE) exec supabase-db psql -U postgres -d supabase

db-console: shell-db ## Alias para shell-db

stats: ## Estatísticas dos leads
	@echo "$(GREEN)Estatísticas dos Leads:$(NC)"
	@$(COMPOSE) exec -T supabase-db psql -U postgres -d supabase -c "SELECT * FROM get_daily_stats();"
	@echo ""
	@echo "$(GREEN)Top Desafios:$(NC)"
	@$(COMPOSE) exec -T supabase-db psql -U postgres -d supabase -c "SELECT * FROM get_top_challenges(5);"

qualified-today: ## Leads qualificados hoje
	@echo "$(GREEN)Leads Qualificados Hoje:$(NC)"
	@$(COMPOSE) exec -T supabase-db psql -U postgres -d supabase -c "SELECT nome, empresa, lead_score, qualified_at FROM leads WHERE DATE(qualified_at) = CURRENT_DATE ORDER BY lead_score DESC;"

test-webhook: ## Testa o webhook do N8N
	@echo "$(GREEN)Testando webhook...$(NC)"
	@curl -X POST http://localhost:5678/webhook/whatsapp-webhook \
		-H "Content-Type: application/json" \
		-d '{"body":{"message":{"from":"5511999999999","text":"Teste de webhook","type":"text"}}}' \
		&& echo "\n$(GREEN)✓ Webhook respondeu!$(NC)" \
		|| echo "\n$(RED)✗ Webhook não respondeu!$(NC)"

qrcode: ## Mostra QR Code do WhatsApp
	@echo "$(GREEN)Gerando QR Code...$(NC)"
	@echo "Acesse: http://localhost:8080/manager"

open-urls: ## Abre todas as URLs no navegador
	@echo "$(GREEN)Abrindo interfaces...$(NC)"
	@xdg-open http://localhost:8080 2>/dev/null || open http://localhost:8080 2>/dev/null || echo "Evolution API: http://localhost:8080"
	@xdg-open http://localhost:5678 2>/dev/null || open http://localhost:5678 2>/dev/null || echo "N8N: http://localhost:5678"
	@xdg-open http://localhost:54323 2>/dev/null || open http://localhost:54323 2>/dev/null || echo "Supabase: http://localhost:54323"
	@xdg-open http://localhost:9000 2>/dev/null || open http://localhost:9000 2>/dev/null || echo "Portainer: http://localhost:9000"

update: ## Atualiza imagens Docker
	@echo "$(GREEN)Atualizando imagens...$(NC)"
	$(COMPOSE) pull
	@echo "$(GREEN)✓ Imagens atualizadas! Execute 'make restart' para aplicar.$(NC)"

monitor: ## Monitor em tempo real dos containers
	@watch -n 2 docker stats --no-stream

top: monitor ## Alias para monitor

export-leads: ## Exporta leads qualificados para CSV
	@echo "$(GREEN)Exportando leads...$(NC)"
	@$(COMPOSE) exec -T supabase-db psql -U postgres -d supabase \
		-c "COPY (SELECT * FROM leads WHERE status = 'qualificado') TO STDOUT WITH CSV HEADER" \
		> leads_qualificados_$(DATE).csv
	@echo "$(GREEN)✓ Exportado: leads_qualificados_$(DATE).csv$(NC)"

check-env: ## Valida arquivo .env
	@echo "$(GREEN)Validando .env...$(NC)"
	@if [ ! -f .env ]; then \
		echo "$(RED)✗ Arquivo .env não encontrado!$(NC)"; \
		echo "Execute: make install"; \
		exit 1; \
	fi
	@grep -q "EVOLUTION_API_KEY=" .env || (echo "$(RED)✗ EVOLUTION_API_KEY não configurada$(NC)" && exit 1)
	@grep -q "ANTHROPIC_API_KEY=" .env || (echo "$(RED)✗ ANTHROPIC_API_KEY não configurada$(NC)" && exit 1)
	@echo "$(GREEN)✓ .env válido!$(NC)"

dev: check-env start ## Inicia em modo desenvolvimento
	@echo "$(GREEN)Ambiente de desenvolvimento pronto!$(NC)"
	@echo ""
	@echo "URLs de acesso:"
	@echo "  Evolution API: http://localhost:8080"
	@echo "  N8N:          http://localhost:5678"
	@echo "  Supabase:     http://localhost:54323"
	@echo "  Portainer:    http://localhost:9000"
	@echo ""
	@make stats

prod: check-env ## Inicia em modo produção
	@echo "$(GREEN)Iniciando em modo produção...$(NC)"
	$(COMPOSE) -f docker-compose.yml -f docker-compose.prod.yml up -d
	@echo "$(GREEN)✓ Ambiente de produção iniciado!$(NC)"

reset: ## Reset completo (para + remove + limpa + instala + inicia)
	@echo "$(YELLOW)Fazendo reset completo...$(NC)"
	@make down
	@make clean
	@make install
	@make start
	@echo "$(GREEN)✓ Reset completo realizado!$(NC)"
