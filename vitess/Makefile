.PHONY: help setup start stop restart clean init status health tablets keyspaces vschema connect logs vtorc-logs ui fix backup restore

# Colors for output (use with printf)
GREEN  := \033[0;32m
BLUE   := \033[0;34m
YELLOW := \033[0;33m
RED    := \033[0;31m
NC     := \033[0m # No Color

# Default target
.DEFAULT_GOAL := help

help: ## Show this help message
	@printf '$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)\n'
	@printf '$(BLUE)         Vitess Cluster Management$(NC)\n'
	@printf '$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)\n'
	@printf '\n'
	@printf '$(GREEN)📦 Setup Commands:$(NC)\n'
	@printf '  $(YELLOW)make setup$(NC)      - Full setup (start + initialize cluster)\n'
	@printf '  $(YELLOW)make start$(NC)      - Start all containers\n'
	@printf '  $(YELLOW)make init$(NC)       - Initialize cluster (set policies + elect primaries)\n'
	@printf '\n'
	@printf '$(GREEN)⚙️  Management Commands:$(NC)\n'
	@printf '  $(YELLOW)make stop$(NC)       - Stop all containers (keeps data)\n'
	@printf '  $(YELLOW)make restart$(NC)    - Restart all containers\n'
	@printf '  $(YELLOW)make clean$(NC)      - Remove all containers and volumes (DELETES DATA)\n'
	@printf '  $(YELLOW)make status$(NC)     - Show status of all containers\n'
	@printf '  $(YELLOW)make logs$(NC)       - View logs from all containers\n'
	@printf '\n'
	@printf '$(GREEN)🔍 Query Commands:$(NC)\n'
	@printf '  $(YELLOW)make tablets$(NC)    - Show all tablets and their status\n'
	@printf '  $(YELLOW)make keyspaces$(NC)  - Show all keyspaces\n'
	@printf '  $(YELLOW)make shards$(NC)     - Show all shards\n'
	@printf '  $(YELLOW)make vschema$(NC)    - Show VSchema for test_keyspace\n'
	@printf '  $(YELLOW)make schema$(NC)     - Show schema for test_keyspace\n'
	@printf '  $(YELLOW)make policies$(NC)   - Show durability policies\n'
	@printf '  $(YELLOW)make connect$(NC)    - Connect to MySQL via VTGate\n'
	@printf '\n'
	@printf '$(GREEN)🔧 Troubleshooting:$(NC)\n'
	@printf '  $(YELLOW)make health$(NC)     - Check cluster health\n'
	@printf '  $(YELLOW)make fix$(NC)        - Fix NOT_SERVING tablets\n'
	@printf '  $(YELLOW)make vtorc-logs$(NC) - View VTOrc logs\n'
	@printf '  $(YELLOW)make tablet-logs$(NC) - View all tablet logs\n'
	@printf '  $(YELLOW)make ui$(NC)         - Show all web interface URLs\n'
	@printf '\n'
	@printf '$(GREEN)🧪 Testing:$(NC)\n'
	@printf '  $(YELLOW)make test-failover$(NC) - Test automatic failover\n'
	@printf '  $(YELLOW)make dev-reset$(NC)  - Complete reset for development\n'
	@printf '\n'
	@printf '$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)\n'
	@printf '$(BLUE)Quick Start:$(NC)\n'
	@printf '  1. $(YELLOW)make setup$(NC)     - First time setup\n'
	@printf '  2. $(YELLOW)make ui$(NC)        - View all web interfaces\n'
	@printf '  3. $(YELLOW)make connect$(NC)   - Connect to MySQL\n'
	@printf '\n'
	@printf '$(RED)⚠️  After docker-compose down -v: ALWAYS run make setup$(NC)\n'
	@printf '$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)\n'
	@printf '\n'

# Setup Commands
setup: start init ## Full setup (start containers + initialize cluster)
	@printf "$(GREEN)✓ Cluster setup complete!$(NC)\n"
	@make ui

start: ## Start all containers
	@printf "$(BLUE)Starting Vitess cluster...$(NC)\n"
	@docker-compose up -d
	@printf "$(GREEN)✓ Containers started. Waiting for health checks...$(NC)\n"
	@sleep 5
	@make status

init: ## Initialize cluster (set policies + elect primaries)
	@printf "$(BLUE)Initializing cluster...$(NC)\n"
	@./init-cluster.sh
	@printf "$(GREEN)✓ Cluster initialized!$(NC)\n"

# Management Commands
stop: ## Stop all containers (keeps data)
	@printf "$(BLUE)Stopping containers...$(NC)\n"
	@docker-compose down
	@printf "$(GREEN)✓ Containers stopped. Data preserved.$(NC)\n"

restart: stop start ## Restart all containers
	@printf "$(YELLOW)Checking if initialization is needed...$(NC)\n"
	@sleep 10
	@if ! docker-compose exec -T vtctld /vt/bin/vtctldclient --server vtctld:15999 GetKeyspace test_keyspace 2>&1 | grep -q 'durability_policy.*none'; then \
		printf "$(RED)⚠ Durability policies not set. Running initialization...$(NC)\n"; \
		make init; \
	else \
		printf "$(GREEN)✓ Cluster state restored from etcd$(NC)\n"; \
	fi

clean: ## Stop and remove all containers and volumes (DELETES ALL DATA)
	@printf "$(RED)⚠ WARNING: This will delete ALL cluster data!$(NC)\n"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		printf "$(RED)Removing all containers and volumes...$(NC)\n"; \
		docker-compose down -v; \
		printf "$(YELLOW)✓ All data deleted. Run 'make setup' to start fresh.$(NC)\n"; \
	else \
		printf "$(GREEN)Cancelled.$(NC)\n"; \
	fi

status: ## Show status of all containers
	@printf "$(BLUE)Container Status:$(NC)\n"
	@docker-compose ps

# Query Commands
tablets: ## Show all tablets and their status
	@printf "$(BLUE)Tablet Status:$(NC)\n"
	@./scripts/lvtctl.sh GetTablets

keyspaces: ## Show all keyspaces
	@printf "$(BLUE)Keyspaces:$(NC)\n"
	@./scripts/lvtctl.sh GetKeyspaces

vschema: ## Show VSchema for test_keyspace
	@printf "$(BLUE)VSchema for test_keyspace:$(NC)\n"
	@./scripts/lvtctl.sh GetVSchema test_keyspace

shards: ## Show all shards
	@printf "$(BLUE)Shards:$(NC)\n"
	@./scripts/lvtctl.sh GetShard test_keyspace/-80
	@./scripts/lvtctl.sh GetShard test_keyspace/80-
	@./scripts/lvtctl.sh GetShard lookup_keyspace/-

connect: ## Connect to MySQL via VTGate
	@printf "$(BLUE)Connecting to VTGate on port 15306...$(NC)\n"
	@printf "$(YELLOW)Tip: Use 'show databases;' to see keyspaces$(NC)\n"
	@mysql -h 127.0.0.1 -P 15306

# Troubleshooting
health: ## Check cluster health
	@printf "$(BLUE)=== Cluster Health Check ===$(NC)\n"
	@printf "\n"
	@printf "$(YELLOW)Container Status:$(NC)\n"
	@docker-compose ps --format "table {{.Name}}\t{{.Status}}" | grep -E "(vtorc|vttablet|vtgate|vtctld)" || true
	@printf "\n"
	@printf "$(YELLOW)Tablet Status:$(NC)\n"
	@./scripts/lvtctl.sh GetTablets 2>/dev/null || printf "$(RED)✗ Cannot get tablets$(NC)\n"
	@printf "\n"
	@printf "$(YELLOW)Durability Policies:$(NC)\n"
	@./scripts/lvtctl.sh GetKeyspace test_keyspace 2>&1 | grep durability_policy || printf "$(RED)✗ Policy not set$(NC)\n"
	@./scripts/lvtctl.sh GetKeyspace lookup_keyspace 2>&1 | grep durability_policy || printf "$(RED)✗ Policy not set$(NC)\n"
	@printf "\n"
	@printf "$(YELLOW)VTOrc Health:$(NC)\n"
	@if docker-compose logs vtorc --since 2m 2>/dev/null | grep -q "ignoring keyspace.*no durability_policy"; then \
		printf "$(RED)✗ VTOrc errors detected (last 2 min) - run 'make fix'$(NC)\n"; \
	else \
		printf "$(GREEN)✓ VTOrc running without errors$(NC)\n"; \
	fi

fix: init ## Fix NOT_SERVING tablets (runs init-cluster.sh)
	@printf "$(GREEN)✓ Cluster should now be healthy$(NC)\n"
	@make health

logs: ## View logs from all containers
	@docker-compose logs --tail=50 -f

vtorc-logs: ## View VTOrc logs
	@printf "$(BLUE)VTOrc Logs (press Ctrl+C to exit):$(NC)\n"
	@docker-compose logs vtorc -f

tablet-logs: ## View logs from all tablets
	@printf "$(BLUE)Tablet Logs (press Ctrl+C to exit):$(NC)\n"
	@docker-compose logs vttablet101 vttablet102 vttablet201 vttablet202 vttablet301 vttablet302 -f

ui: ## Show all web interface URLs
	@printf "$(BLUE)=== Vitess Web Interfaces ===$(NC)\n"
	@printf "\n"
	@printf "$(GREEN)Management:$(NC)\n"
	@printf "  VTAdmin Web UI:  $(YELLOW)http://localhost:14201$(NC)\n"
	@printf "  VTAdmin API:     $(YELLOW)http://localhost:14200/api/clusters$(NC)\n"
	@printf "  VTOrc (Failover): $(YELLOW)http://localhost:13000/debug/status$(NC)\n"
	@printf "\n"
	@printf "$(GREEN)Monitoring:$(NC)\n"
	@printf "  VTGate Status:   $(YELLOW)http://localhost:15099/debug/status$(NC)\n"
	@printf "  VTCtld Status:   $(YELLOW)http://localhost:15000/debug/status$(NC)\n"
	@printf "\n"
	@printf "$(GREEN)Tablets:$(NC)\n"
	@printf "  vttablet101:     $(YELLOW)http://localhost:15101/debug/status$(NC)\n"
	@printf "  vttablet102:     $(YELLOW)http://localhost:15102/debug/status$(NC)\n"
	@printf "  vttablet201:     $(YELLOW)http://localhost:15201/debug/status$(NC)\n"
	@printf "  vttablet202:     $(YELLOW)http://localhost:15202/debug/status$(NC)\n"
	@printf "  vttablet301:     $(YELLOW)http://localhost:15301/debug/status$(NC)\n"
	@printf "  vttablet302:     $(YELLOW)http://localhost:15302/debug/status$(NC)\n"
	@printf "\n"
	@printf "$(GREEN)MySQL Connection:$(NC)\n"
	@printf "  mysql -h 127.0.0.1 -P 15306\n"
	@printf "\n"

test-failover: ## Test automatic failover (stops vttablet101)
	@printf "$(RED)⚠ Testing failover by stopping vttablet101...$(NC)\n"
	@printf "$(YELLOW)Current primary for test_keyspace/-80:$(NC)\n"
	@./scripts/lvtctl.sh GetTablets | grep "test_keyspace.*-80.*primary"
	@printf "\n"
	@printf "$(RED)Stopping vttablet101...$(NC)\n"
	@docker-compose stop vttablet101
	@printf "$(YELLOW)Waiting for VTOrc to detect failure (20s)...$(NC)\n"
	@sleep 20
	@printf "$(YELLOW)New primary should be vttablet102:$(NC)\n"
	@./scripts/lvtctl.sh GetTablets | grep "test_keyspace.*-80.*primary"
	@printf "\n"
	@printf "$(GREEN)Restarting vttablet101...$(NC)\n"
	@docker-compose start vttablet101
	@printf "$(GREEN)✓ Failover test complete$(NC)\n"

schema: ## Show schema for test_keyspace
	@printf "$(BLUE)Schema for test_keyspace:$(NC)\n"
	@./scripts/lvtctl.sh GetSchema test_keyspace

policies: ## Show durability policies for all keyspaces
	@printf "$(BLUE)Durability Policies:$(NC)\n"
	@printf "$(YELLOW)test_keyspace:$(NC)\n"
	@./scripts/lvtctl.sh GetKeyspace test_keyspace | grep durability_policy
	@printf "$(YELLOW)lookup_keyspace:$(NC)\n"
	@./scripts/lvtctl.sh GetKeyspace lookup_keyspace | grep durability_policy

# Development helpers
dev-reset: clean setup ## Complete reset for development
	@printf "$(GREEN)✓ Development environment reset complete$(NC)\n"

ps: status ## Alias for status

watch-health: ## Watch cluster health (refreshes every 5s)
	@watch -n 5 'make health'
