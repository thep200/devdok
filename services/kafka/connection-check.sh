#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "${YELLOW}Testing Kafka connection to 127.0.0.1...${NC}"

# Test external ports
echo "\n${YELLOW}Testing External Ports:${NC}"
nc -z -v -w 5 127.0.0.1 9092 2>&1 && echo "${GREEN}✓ Successfully connected to Kafka at 127.0.0.1:9092${NC}" || echo "${RED}✗ Failed to connect to Kafka at 127.0.0.1:9092${NC}"

# Test Kafka UI
echo "\n${YELLOW}Testing Kafka UI:${NC}"
nc -z -v -w 5 127.0.0.1 8080 2>&1 && echo "${GREEN}✓ Successfully connected to Kafka UI at 127.0.0.1:8080${NC}" || echo "${RED}✗ Failed to connect to Kafka UI at 127.0.0.1:8080${NC}"

# Test Debezium Connect
echo "\n${YELLOW}Testing Debezium Connect:${NC}"
nc -z -v -w 5 127.0.0.1 8083 2>&1 && echo "${GREEN}✓ Successfully connected to Debezium Connect at 127.0.0.1:8083${NC}" || echo "${RED}✗ Failed to connect to Debezium Connect at 127.0.0.1:8083${NC}"

echo "\n${YELLOW}Application Configuration:${NC}"
echo "External applications should use this bootstrap server:"
echo "${GREEN}bootstrap.servers=127.0.0.1:9092${NC}"

echo "\n${YELLOW}Container-to-Container Configuration:${NC}"
echo "Services inside containers should use:"
echo "${GREEN}bootstrap.servers=kafka00:29092${NC}"

echo "\n${YELLOW}Kafka UI Access:${NC}"
echo "${GREEN}http://127.0.0.1:8080${NC}"

echo "\n${YELLOW}Debezium Connect API:${NC}"
echo "${GREEN}http://127.0.0.1:8083${NC}"
