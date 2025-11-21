.PHONY: help setup start stop restart clean init status health tablets keyspaces vschema connect logs vtorc-logs ui fix backup restore \
	shard-create-keyspace shard-list-shards shard-create-shard shard-apply-schema shard-apply-vschema shard-elect-primary shard-info shard-wizard shard-delete-keyspace

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
	@printf '$(GREEN)🔀 Sharding Management:$(NC)\n'
	@printf '  $(YELLOW)make shard-wizard$(NC) - Interactive wizard to create new sharded keyspace\n'
	@printf '  $(YELLOW)make shard-create-keyspace$(NC) - Create a new keyspace\n'
	@printf '  $(YELLOW)make shard-create-shard$(NC) - Create a new shard for keyspace\n'
	@printf '  $(YELLOW)make shard-apply-schema$(NC) - Apply schema to keyspace\n'
	@printf '  $(YELLOW)make shard-apply-vschema$(NC) - Apply VSchema to keyspace\n'
	@printf '  $(YELLOW)make shard-elect-primary$(NC) - Elect primary tablet for shard\n'
	@printf '  $(YELLOW)make shard-list-shards$(NC) - List all shards for a keyspace\n'
	@printf '  $(YELLOW)make shard-info$(NC) - Show detailed info for keyspace/shard\n'
	@printf '  $(YELLOW)make shard-delete-keyspace$(NC) - Delete a keyspace (DANGER)\n'
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
	@./scripts/init-cluster.sh
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

fix: init ## Fix NOT_SERVING tablets (runs scripts/init-cluster.sh)
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

# ========================================
# Sharding Management Commands
# ========================================

shard-wizard: ## Interactive wizard to create a new sharded keyspace
	@printf "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)\n"
	@printf "$(BLUE)         Vitess Sharding Wizard$(NC)\n"
	@printf "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)\n"
	@printf "\n"
	@printf "$(YELLOW)This wizard will guide you through creating a sharded keyspace.$(NC)\n"
	@printf "\n"
	@read -p "Enter keyspace name: " KEYSPACE_NAME; \
	printf "\n"; \
	printf "$(YELLOW)Choose sharding strategy:$(NC)\n"; \
	printf "  1. Unsharded (single shard '-')\n"; \
	printf "  2. 2 shards (hash-based: -80, 80-)\n"; \
	printf "  3. 4 shards (hash-based: -40, 40-80, 80-c0, c0-)\n"; \
	printf "  4. Custom shards\n"; \
	read -p "Enter choice [1-4]: " SHARD_CHOICE; \
	printf "\n"; \
	case $$SHARD_CHOICE in \
		1) SHARDS="-";; \
		2) SHARDS="-80 80-";; \
		3) SHARDS="-40 40-80 80-c0 c0-";; \
		4) read -p "Enter shards (space-separated, e.g., '-80 80-'): " SHARDS;; \
		*) printf "$(RED)Invalid choice$(NC)\n"; exit 1;; \
	esac; \
	printf "\n"; \
	printf "$(GREEN)Configuration:$(NC)\n"; \
	printf "  Keyspace: $$KEYSPACE_NAME\n"; \
	printf "  Shards: $$SHARDS\n"; \
	printf "\n"; \
	read -p "Proceed? [y/N] " -n 1 -r; \
	echo; \
	if [[ ! $$REPLY =~ ^[Yy]$$ ]]; then \
		printf "$(YELLOW)Cancelled.$(NC)\n"; \
		exit 0; \
	fi; \
	printf "\n$(BLUE)Step 1: Creating keyspace $$KEYSPACE_NAME...$(NC)\n"; \
	./scripts/lvtctl.sh CreateKeyspace $$KEYSPACE_NAME || true; \
	printf "$(GREEN)✓ Keyspace created$(NC)\n\n"; \
	printf "$(BLUE)Step 2: Setting durability policy...$(NC)\n"; \
	./scripts/lvtctl.sh SetKeyspaceDurabilityPolicy --durability-policy=none $$KEYSPACE_NAME; \
	printf "$(GREEN)✓ Durability policy set$(NC)\n\n"; \
	for SHARD in $$SHARDS; do \
		printf "$(BLUE)Step 3: Creating shard $$KEYSPACE_NAME/$$SHARD...$(NC)\n"; \
		./scripts/lvtctl.sh CreateShard $$KEYSPACE_NAME/$$SHARD || true; \
		printf "$(GREEN)✓ Shard $$SHARD created$(NC)\n\n"; \
	done; \
	printf "$(GREEN)✓ Sharding setup complete!$(NC)\n\n"; \
	printf "$(YELLOW)Next steps:$(NC)\n"; \
	printf "  1. Add tablet services to docker-compose.yml for each shard\n"; \
	printf "  2. Create schema SQL file in scripts/sql/\n"; \
	printf "  3. Run: make shard-apply-schema KEYSPACE=$$KEYSPACE_NAME SCHEMA_FILE=your_schema.sql\n"; \
	printf "  4. Create VSchema JSON file in scripts/configs/\n"; \
	printf "  5. Run: make shard-apply-vschema KEYSPACE=$$KEYSPACE_NAME VSCHEMA_FILE=your_vschema.json\n"; \
	printf "  6. Restart cluster: make restart\n"; \
	printf "  7. Elect primaries for each shard using: make shard-elect-primary\n"; \
	printf "\n"

shard-create-keyspace: ## Create a new keyspace (Usage: make shard-create-keyspace KEYSPACE=my_keyspace)
	@if [ -z "$(KEYSPACE)" ]; then \
		printf "$(RED)Error: KEYSPACE not specified$(NC)\n"; \
		printf "Usage: make shard-create-keyspace KEYSPACE=my_keyspace\n"; \
		exit 1; \
	fi
	@printf "$(BLUE)Creating keyspace $(KEYSPACE)...$(NC)\n"
	@./scripts/lvtctl.sh CreateKeyspace $(KEYSPACE) || printf "$(YELLOW)Keyspace may already exist$(NC)\n"
	@printf "$(BLUE)Setting durability policy...$(NC)\n"
	@./scripts/lvtctl.sh SetKeyspaceDurabilityPolicy --durability-policy=none $(KEYSPACE)
	@printf "$(GREEN)✓ Keyspace $(KEYSPACE) created$(NC)\n"

shard-create-shard: ## Create a new shard (Usage: make shard-create-shard KEYSPACE=my_keyspace SHARD=-80)
	@if [ -z "$(KEYSPACE)" ] || [ -z "$(SHARD)" ]; then \
		printf "$(RED)Error: KEYSPACE or SHARD not specified$(NC)\n"; \
		printf "Usage: make shard-create-shard KEYSPACE=my_keyspace SHARD=-80\n"; \
		exit 1; \
	fi
	@printf "$(BLUE)Creating shard $(KEYSPACE)/$(SHARD)...$(NC)\n"
	@./scripts/lvtctl.sh CreateShard $(KEYSPACE)/$(SHARD) || printf "$(YELLOW)Shard may already exist$(NC)\n"
	@printf "$(GREEN)✓ Shard $(KEYSPACE)/$(SHARD) created$(NC)\n"
	@printf "$(YELLOW)Note: Add tablet services to docker-compose.yml and restart$(NC)\n"

shard-list-shards: ## List all shards for a keyspace (Usage: make shard-list-shards KEYSPACE=my_keyspace)
	@if [ -z "$(KEYSPACE)" ]; then \
		printf "$(RED)Error: KEYSPACE not specified$(NC)\n"; \
		printf "Usage: make shard-list-shards KEYSPACE=my_keyspace\n"; \
		exit 1; \
	fi
	@printf "$(BLUE)Shards for keyspace $(KEYSPACE):$(NC)\n"
	@./scripts/lvtctl.sh FindAllShardsInKeyspace $(KEYSPACE)

shard-apply-schema: ## Apply schema to keyspace (Usage: make shard-apply-schema KEYSPACE=my_keyspace SCHEMA_FILE=my_schema.sql)
	@if [ -z "$(KEYSPACE)" ] || [ -z "$(SCHEMA_FILE)" ]; then \
		printf "$(RED)Error: KEYSPACE or SCHEMA_FILE not specified$(NC)\n"; \
		printf "Usage: make shard-apply-schema KEYSPACE=my_keyspace SCHEMA_FILE=my_schema.sql\n"; \
		printf "       (SCHEMA_FILE should be in scripts/sql/ directory)\n"; \
		exit 1; \
	fi
	@printf "$(BLUE)Applying schema $(SCHEMA_FILE) to keyspace $(KEYSPACE)...$(NC)\n"
	@docker-compose exec -T vtctld /vt/bin/vtctldclient --server vtctld:15999 ApplySchema --sql-file /script/sql/$(SCHEMA_FILE) $(KEYSPACE)
	@printf "$(GREEN)✓ Schema applied to $(KEYSPACE)$(NC)\n"

shard-apply-vschema: ## Apply VSchema to keyspace (Usage: make shard-apply-vschema KEYSPACE=my_keyspace VSCHEMA_FILE=my_vschema.json)
	@if [ -z "$(KEYSPACE)" ] || [ -z "$(VSCHEMA_FILE)" ]; then \
		printf "$(RED)Error: KEYSPACE or VSCHEMA_FILE not specified$(NC)\n"; \
		printf "Usage: make shard-apply-vschema KEYSPACE=my_keyspace VSCHEMA_FILE=my_vschema.json\n"; \
		printf "       (VSCHEMA_FILE should be in scripts/configs/ directory)\n"; \
		exit 1; \
	fi
	@printf "$(BLUE)Applying VSchema $(VSCHEMA_FILE) to keyspace $(KEYSPACE)...$(NC)\n"
	@docker-compose exec -T vtctld /vt/bin/vtctldclient --server vtctld:15999 ApplyVSchema --vschema-file /script/configs/$(VSCHEMA_FILE) $(KEYSPACE)
	@printf "$(GREEN)✓ VSchema applied to $(KEYSPACE)$(NC)\n"

shard-elect-primary: ## Elect primary tablet for shard (Usage: make shard-elect-primary KEYSPACE=my_keyspace SHARD=-80 TABLET_ALIAS=test-0000000401)
	@if [ -z "$(KEYSPACE)" ] || [ -z "$(SHARD)" ] || [ -z "$(TABLET_ALIAS)" ]; then \
		printf "$(RED)Error: KEYSPACE, SHARD, or TABLET_ALIAS not specified$(NC)\n"; \
		printf "Usage: make shard-elect-primary KEYSPACE=my_keyspace SHARD=-80 TABLET_ALIAS=test-0000000401\n"; \
		printf "\nAvailable tablets:\n"; \
		./scripts/lvtctl.sh GetTablets 2>/dev/null || true; \
		exit 1; \
	fi
	@printf "$(BLUE)Electing $(TABLET_ALIAS) as primary for $(KEYSPACE)/$(SHARD)...$(NC)\n"
	@./scripts/lvtctl.sh PlannedReparentShard --new-primary $(TABLET_ALIAS) $(KEYSPACE)/$(SHARD)
	@printf "$(GREEN)✓ Primary elected for $(KEYSPACE)/$(SHARD)$(NC)\n"

shard-info: ## Show detailed info for keyspace/shard (Usage: make shard-info KEYSPACE=my_keyspace [SHARD=-80])
	@if [ -z "$(KEYSPACE)" ]; then \
		printf "$(RED)Error: KEYSPACE not specified$(NC)\n"; \
		printf "Usage: make shard-info KEYSPACE=my_keyspace [SHARD=-80]\n"; \
		exit 1; \
	fi
	@printf "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)\n"
	@printf "$(BLUE)Keyspace Information: $(KEYSPACE)$(NC)\n"
	@printf "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)\n"
	@printf "\n$(YELLOW)Keyspace Details:$(NC)\n"
	@./scripts/lvtctl.sh GetKeyspace $(KEYSPACE) 2>/dev/null || printf "$(RED)Keyspace not found$(NC)\n"
	@printf "\n$(YELLOW)Shards:$(NC)\n"
	@./scripts/lvtctl.sh FindAllShardsInKeyspace $(KEYSPACE) 2>/dev/null || printf "$(RED)No shards found$(NC)\n"
	@if [ -n "$(SHARD)" ]; then \
		printf "\n$(YELLOW)Shard Details ($(SHARD)):$(NC)\n"; \
		./scripts/lvtctl.sh GetShard $(KEYSPACE)/$(SHARD) 2>/dev/null || printf "$(RED)Shard not found$(NC)\n"; \
	fi
	@printf "\n$(YELLOW)Tablets:$(NC)\n"
	@./scripts/lvtctl.sh GetTablets 2>/dev/null | grep $(KEYSPACE) || printf "$(RED)No tablets found$(NC)\n"
	@printf "\n$(YELLOW)VSchema:$(NC)\n"
	@./scripts/lvtctl.sh GetVSchema $(KEYSPACE) 2>/dev/null || printf "$(RED)No VSchema found$(NC)\n"
	@printf "\n"

shard-delete-keyspace: ## Delete a keyspace (DANGER - Usage: make shard-delete-keyspace KEYSPACE=my_keyspace)
	@if [ -z "$(KEYSPACE)" ]; then \
		printf "$(RED)Error: KEYSPACE not specified$(NC)\n"; \
		printf "Usage: make shard-delete-keyspace KEYSPACE=my_keyspace\n"; \
		exit 1; \
	fi
	@printf "$(RED)⚠ WARNING: This will delete keyspace $(KEYSPACE) and all its data!$(NC)\n"
	@read -p "Are you absolutely sure? Type 'DELETE $(KEYSPACE)' to confirm: " CONFIRM; \
	if [ "$$CONFIRM" = "DELETE $(KEYSPACE)" ]; then \
		printf "$(RED)Deleting keyspace $(KEYSPACE)...$(NC)\n"; \
		./scripts/lvtctl.sh DeleteKeyspace --recursive $(KEYSPACE); \
		printf "$(YELLOW)✓ Keyspace $(KEYSPACE) deleted$(NC)\n"; \
	else \
		printf "$(GREEN)Cancelled.$(NC)\n"; \
	fi
