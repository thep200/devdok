.PHONY: all net-shared

all: net-shared

net-shared:
	@if ! docker network ls | grep -q "shared"; then \
		echo "Creating Docker network 'shared'..."; \
		docker network create shared; \
		echo "Created 'shared' network successfully!"; \
	else \
		echo "Network 'shared' already exists!"; \
	fi
