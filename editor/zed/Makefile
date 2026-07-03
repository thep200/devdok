# Makefile for Zed Editor Configuration Management
# Author: Generated for Zed configuration setup

.PHONY: zed-check zed-config help

# Default target
all: zed-check zed-config

# Colors for output
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
NC := \033[0m # No Color

# Detect OS and set Zed config directory
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    ZED_CONFIG_DIR := $(HOME)/.config/zed
    ZED_BINARY := /Applications/Zed.app/Contents/MacOS/zed
else ifeq ($(UNAME_S),Linux)
    ZED_CONFIG_DIR := $(HOME)/.config/zed
    ZED_BINARY := $(shell which zed)
else
    $(error Unsupported operating system: $(UNAME_S))
endif

# Check if Zed is installed
zed-check:
ifeq ($(UNAME_S),Darwin)
	@if [ -d "/Applications/Zed.app" ]; then \
		echo "$(GREEN)✓ Zed is installed at /Applications/Zed.app$(NC)"; \
	else \
		echo "$(RED)✗ Zed is not installed. Please install Zed from https://zed.dev$(NC)"; \
		exit 1; \
	fi
else
	@if command -v zed >/dev/null 2>&1; then \
		echo "$(GREEN)✓ Zed is installed at $$(which zed)$(NC)"; \
	else \
		echo "$(RED)✗ Zed is not installed. Please install Zed from your package manager or https://zed.dev$(NC)"; \
		exit 1; \
	fi
endif

# Install configuration files
zed-config: zed-check
	@echo "$(YELLOW)Installing Zed configuration files...$(NC)"
	@echo "$(YELLOW)Target directory: $(ZED_CONFIG_DIR)$(NC)"

	# Create Zed config directory if it doesn't exist
	@mkdir -p "$(ZED_CONFIG_DIR)"

	# Backup existing configurations
	@if [ -f "$(ZED_CONFIG_DIR)/settings.json" ]; then \
		echo "$(YELLOW)Backing up existing settings.json to settings_backup.json$(NC)"; \
		cp "$(ZED_CONFIG_DIR)/settings.json" "$(ZED_CONFIG_DIR)/settings_backup.json"; \
	fi
	@if [ -f "$(ZED_CONFIG_DIR)/keymap.json" ]; then \
		echo "$(YELLOW)Backing up existing keymap.json to keymap_backup.json$(NC)"; \
		cp "$(ZED_CONFIG_DIR)/keymap.json" "$(ZED_CONFIG_DIR)/keymap_backup.json"; \
	fi
	@if [ -f "$(ZED_CONFIG_DIR)/tasks.json" ]; then \
		echo "$(YELLOW)Backing up existing tasks.json to tasks_backup.json$(NC)"; \
		cp "$(ZED_CONFIG_DIR)/tasks.json" "$(ZED_CONFIG_DIR)/tasks_backup.json"; \
	fi

	# Copy configuration files
	@echo "$(GREEN)Copying settings.json...$(NC)"
	@cp setting/settings.json "$(ZED_CONFIG_DIR)/settings.json"

	@echo "$(GREEN)Copying keymap.json...$(NC)"
	@cp keymap/keymap.json "$(ZED_CONFIG_DIR)/keymap.json"

	@echo "$(GREEN)Copying tasks.json...$(NC)"
	@cp task/tasks.json "$(ZED_CONFIG_DIR)/tasks.json"

	# Copy themes if themes directory exists in target
	@echo "$(GREEN)Copying themes...$(NC)"
	@mkdir -p "$(ZED_CONFIG_DIR)/themes"
	@if [ -d "themes" ]; then \
		cp themes/*.json "$(ZED_CONFIG_DIR)/themes/" 2>/dev/null || true; \
		echo "$(GREEN)✓ Themes copied to $(ZED_CONFIG_DIR)/themes/$(NC)"; \
	else \
		echo "$(YELLOW)No themes directory found, skipping...$(NC)"; \
	fi

	@echo "$(GREEN)✓ Configuration files installed successfully!$(NC)"
	@echo "$(GREEN)✓ Configuration location: $(ZED_CONFIG_DIR)$(NC)"

# Show current configuration status
zed-status:
	@echo "$(YELLOW)Zed Configuration Status:$(NC)"
	@echo "OS: $(UNAME_S)"
	@echo "Config directory: $(ZED_CONFIG_DIR)"
	@echo "Zed binary: $(ZED_BINARY)"
	@echo ""
	@echo "Configuration files:"

	@if [ -f "$(ZED_CONFIG_DIR)/settings.json" ]; then \
		echo "$(GREEN)✓ settings.json exists$(NC)"; \
	else \
		echo "$(RED)✗ settings.json missing$(NC)"; \
	fi

	@if [ -f "$(ZED_CONFIG_DIR)/keymap.json" ]; then \
		echo "$(GREEN)✓ keymap.json exists$(NC)"; \
	else \
		echo "$(RED)✗ keymap.json missing$(NC)"; \
	fi

	@if [ -f "$(ZED_CONFIG_DIR)/tasks.json" ]; then \
		echo "$(GREEN)✓ tasks.json exists$(NC)"; \
	else \
		echo "$(RED)✗ tasks.json missing$(NC)"; \
	fi

	@if [ -d "$(ZED_CONFIG_DIR)/themes" ]; then \
		echo "$(GREEN)✓ themes directory exists$(NC)"; \
		echo "Themes: $$(ls $(ZED_CONFIG_DIR)/themes/*.json 2>/dev/null | wc -l) files"; \
	else \
		echo "$(RED)✗ themes directory missing$(NC)"; \
	fi

# Show help
help:
	@echo "$(GREEN)Zed Configuration Makefile$(NC)"
	@echo ""
	@echo "Available targets:"
	@echo "  $(YELLOW)all$(NC)        * Check Zed installation and install configurations (default)"
	@echo "  $(YELLOW)zed-check$(NC)  * Check if Zed editor is installed"
	@echo "  $(YELLOW)zed-config$(NC) * Install configuration files to Zed config directory"
	@echo "  $(YELLOW)zed-status$(NC) * Show current configuration status"
	@echo "  $(YELLOW)help$(NC)       * Show this help message"
	@echo ""
	@echo "Configuration will be installed to: $(ZED_CONFIG_DIR)"
