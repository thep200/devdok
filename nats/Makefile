.PHONY: help health info connections jetstream routes all test-pub test-sub web build up down logs restart

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

help: ## Show this help
	@echo "$(BLUE)NATS Monitoring Commands:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

# NATS Monitoring Commands
health: ## Check NATS health status
	@echo "$(BLUE)Checking NATS health...$(NC)"
	@curl -s http://localhost:8222/healthz && echo " $(GREEN)✓ NATS is healthy$(NC)" || echo " $(RED)✗ NATS is not responding$(NC)"

info: ## Get NATS server information
	@echo "$(BLUE)NATS Server Information:$(NC)"
	@curl -s http://localhost:8222/varz | jq '.server_name, .version, .uptime, .mem, .connections, .in_msgs, .out_msgs'

connections: ## Show NATS connections
	@echo "$(BLUE)NATS Connections ($(shell curl -s http://localhost:8222/connz | jq '.num_connections')):$(NC)"
	@curl -s http://localhost:8222/connz | jq '.connections[] | {cid, ip, port, last_activity}'

jetstream: ## Show JetStream information
	@echo "$(BLUE)NATS JetStream Status:$(NC)"
	@curl -s http://localhost:8222/jsz | jq '{config, stats, streams, consumers}'

routes: ## Show NATS routing information
	@echo "$(BLUE)NATS Routes:$(NC)"
	@curl -s http://localhost:8222/routez | jq '.'

stats: ## Show quick stats
	@echo "$(BLUE)NATS Quick Stats:$(NC)"
	@curl -s http://localhost:8222/varz | jq '{server_name, uptime, connections, in_msgs, out_msgs, in_bytes, out_bytes}'

all: ## Show all NATS monitoring information
	@make health
	@echo ""
	@make stats
	@echo ""
	@make connections
	@echo ""
	@make jetstream

# Testing Commands
test-pub: ## Test NATS publish (requires nats CLI)
	@echo "$(BLUE)Testing NATS publish...$(NC)"
	@nats pub test.subject "Hello NATS at $(shell date)" --server=localhost:4222

test-sub: ## Test NATS subscribe (requires nats CLI)
	@echo "$(BLUE)Testing NATS subscribe (press Ctrl+C to stop)...$(NC)"
	@nats sub test.subject --server=localhost:4222

test-req: ## Test NATS request-reply
	@echo "$(BLUE)Testing NATS request-reply...$(NC)"
	@nats reply test.request "Reply at $(shell date)" --server=localhost:4222 &
	@sleep 1
	@nats request test.request "Request at $(shell date)" --server=localhost:4222

# Docker Commands
build: ## Build NATS Docker image
	@echo "$(BLUE)Building NATS image...$(NC)"
	@docker build -t nats-custom .

up: ## Start NATS container
	@echo "$(BLUE)Starting NATS container...$(NC)"
	@docker-compose up -d nats

down: ## Stop NATS container
	@echo "$(BLUE)Stopping NATS container...$(NC)"
	@docker-compose down nats

restart: ## Restart NATS container
	@echo "$(BLUE)Restarting NATS container...$(NC)"
	@docker-compose restart nats

logs: ## Show NATS logs
	@echo "$(BLUE)NATS Logs:$(NC)"
	@docker-compose logs -f nats

# Quick Access
web: ## Open NATS monitoring in browser
	@echo "$(BLUE)Opening NATS monitoring...$(NC)"
	@open http://localhost:8222 || xdg-open http://localhost:8222 || echo "Open http://localhost:8222 manually"

# Stream Management (JetStream)
streams: ## List JetStream streams
	@echo "$(BLUE)JetStream Streams:$(NC)"
	@curl -s http://localhost:8222/jsz | jq '.streams'

create-stream: ## Create test stream (requires nats CLI)
	@echo "$(BLUE)Creating test stream...$(NC)"
	@nats stream add TEST --subjects="test.>" --storage=file --replicas=1 --server=localhost:4222

delete-stream: ## Delete test stream (requires nats CLI)
	@echo "$(BLUE)Deleting test stream...$(NC)"
	@nats stream rm TEST --server=localhost:4222

# Development helpers
dev-watch: ## Watch NATS stats (updates every 2 seconds)
	@echo "$(BLUE)Watching NATS stats (press Ctrl+C to stop)...$(NC)"
	@watch -n 2 'curl -s http://localhost:8222/varz | jq "{connections, in_msgs, out_msgs, mem}"'

dev-test: ## Run development tests
	@make health
	@make test-pub
	@make stats
