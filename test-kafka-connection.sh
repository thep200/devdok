#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Testing Kafka connection to 127.0.0.1...${NC}"

# Test external ports
echo -e "\nTesting External Ports:"
nc -z -v -w 5 127.0.0.1 19092 2>&1 && echo -e "${GREEN}✓ Successfully connected to Kafka00 at 127.0.0.1:19092${NC}" || echo -e "${RED}✗ Failed to connect to Kafka00 at 127.0.0.1:19092${NC}"
nc -z -v -w 5 127.0.0.1 19093 2>&1 && echo -e "${GREEN}✓ Successfully connected to Kafka01 at 127.0.0.1:19093${NC}" || echo -e "${RED}✗ Failed to connect to Kafka01 at 127.0.0.1:19093${NC}"

echo -e "\n${YELLOW}Connection Summary:${NC}"
echo -e "${GREEN}Your Kafka brokers are now configured to be accessible from external applications via:"
echo -e "  - 127.0.0.1:19092 (Broker 0)"
echo -e "  - 127.0.0.1:19093 (Broker 1)${NC}"

echo -e "\n${YELLOW}Application Configuration:${NC}"
echo -e "External applications should use these bootstrap servers:"
echo -e "${GREEN}bootstrap.servers=127.0.0.1:19092,127.0.0.1:19093${NC}"
