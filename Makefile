.PHONY: all net-shared ansible migrate

all: net-shared

# Install Ansible + required collections right after cloning the repo.
ansible:
	@if command -v ansible-playbook >/dev/null 2>&1; then \
		echo "Ansible already installed: $$(ansible --version | head -n1)"; \
	else \
		echo "Installing Ansible..."; \
		if command -v brew >/dev/null 2>&1; then brew install ansible; \
		elif command -v apt-get >/dev/null 2>&1; then sudo apt-get update && sudo apt-get install -y ansible; \
		elif command -v dnf >/dev/null 2>&1; then sudo dnf install -y ansible; \
		elif command -v pacman >/dev/null 2>&1; then sudo pacman -S --noconfirm ansible; \
		elif command -v pip3 >/dev/null 2>&1; then pip3 install --user ansible; \
		else echo "No supported package manager found — install Ansible manually."; exit 1; fi; \
	fi
	@echo "Installing Ansible collections..."
	@ansible-galaxy collection install community.general ansible.windows chocolatey.chocolatey

# Run the environment-sync playbook against the current machine.
migrate:
	ansible-playbook -i 'localhost,' -c local migrate.yaml

net-shared:
	@if ! docker network ls | grep -q "shared"; then \
		echo "Creating Docker network 'shared'..."; \
		docker network create shared; \
		echo "Created 'shared' network successfully!"; \
	else \
		echo "Network 'shared' already exists!"; \
	fi
