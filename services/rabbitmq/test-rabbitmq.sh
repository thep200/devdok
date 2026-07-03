#!/bin/bash

# RabbitMQ Test Script
# This script verifies that RabbitMQ is properly configured and running

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
RABBITMQ_HOST="localhost"
RABBITMQ_PORT="5672"
RABBITMQ_MGMT_PORT="15672"
RABBITMQ_USER="thep200"
RABBITMQ_PASS="root"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              RabbitMQ Connection Test                          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Test 1: Check if container is running
echo -e "${YELLOW}1. Checking if RabbitMQ container is running...${NC}"
if docker ps | grep -q "rabbitmq"; then
    echo -e "${GREEN}✓ RabbitMQ container is running${NC}"
else
    echo -e "${RED}✗ RabbitMQ container is NOT running${NC}"
    echo "  Start it with: docker-compose up -d rabbitmq"
    exit 1
fi
echo ""

# Test 2: Check AMQP port connectivity
echo -e "${YELLOW}2. Testing AMQP port (${RABBITMQ_PORT})...${NC}"
if timeout 5 bash -c "echo >/dev/tcp/${RABBITMQ_HOST}/${RABBITMQ_PORT}" 2>/dev/null; then
    echo -e "${GREEN}✓ AMQP port ${RABBITMQ_PORT} is accessible${NC}"
else
    echo -e "${RED}✗ Cannot connect to AMQP port ${RABBITMQ_PORT}${NC}"
    exit 1
fi
echo ""

# Test 3: Check Management UI port
echo -e "${YELLOW}3. Testing Management UI port (${RABBITMQ_MGMT_PORT})...${NC}"
if timeout 5 bash -c "echo >/dev/tcp/${RABBITMQ_HOST}/${RABBITMQ_MGMT_PORT}" 2>/dev/null; then
    echo -e "${GREEN}✓ Management UI port ${RABBITMQ_MGMT_PORT} is accessible${NC}"
else
    echo -e "${RED}✗ Cannot connect to Management UI port ${RABBITMQ_MGMT_PORT}${NC}"
    exit 1
fi
echo ""

# Test 4: Check Management API authentication
echo -e "${YELLOW}4. Testing Management API authentication...${NC}"
RESPONSE=$(curl -s -w "%{http_code}" -u ${RABBITMQ_USER}:${RABBITMQ_PASS} http://${RABBITMQ_HOST}:${RABBITMQ_MGMT_PORT}/api/whoami)
HTTP_CODE="${RESPONSE: -3}"

if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✓ Authentication successful${NC}"
    USER_NAME=$(echo "${RESPONSE:0:${#RESPONSE}-3}" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
    echo "  User: $USER_NAME"
else
    echo -e "${RED}✗ Authentication failed (HTTP $HTTP_CODE)${NC}"
    exit 1
fi
echo ""

# Test 5: Get RabbitMQ status
echo -e "${YELLOW}5. Fetching RabbitMQ status...${NC}"
STATUS=$(docker exec rabbitmq rabbitmqctl status 2>&1 | head -20)
if echo "$STATUS" | grep -q "RabbitMQ"; then
    echo -e "${GREEN}✓ RabbitMQ status retrieved${NC}"
    RABBITMQ_VERSION=$(echo "$STATUS" | grep "RabbitMQ version" | awk -F': ' '{print $2}')
    echo "  Version: $RABBITMQ_VERSION"
else
    echo -e "${RED}✗ Could not retrieve RabbitMQ status${NC}"
    exit 1
fi
echo ""

# Test 6: List queues
echo -e "${YELLOW}6. Listing queues...${NC}"
QUEUES=$(curl -s -u ${RABBITMQ_USER}:${RABBITMQ_PASS} http://${RABBITMQ_HOST}:${RABBITMQ_MGMT_PORT}/api/queues)
if echo "$QUEUES" | grep -q "name"; then
    echo -e "${GREEN}✓ Queues retrieved successfully${NC}"
    QUEUE_COUNT=$(echo "$QUEUES" | grep -o '"name"' | wc -l)
    echo "  Total queues: $QUEUE_COUNT"
else
    echo -e "${RED}✗ Could not retrieve queues${NC}"
    exit 1
fi
echo ""

# Test 7: List exchanges
echo -e "${YELLOW}7. Listing exchanges...${NC}"
EXCHANGES=$(curl -s -u ${RABBITMQ_USER}:${RABBITMQ_PASS} http://${RABBITMQ_HOST}:${RABBITMQ_MGMT_PORT}/api/exchanges)
if echo "$EXCHANGES" | grep -q "name"; then
    echo -e "${GREEN}✓ Exchanges retrieved successfully${NC}"
    EXCHANGE_COUNT=$(echo "$EXCHANGES" | grep -o '"name"' | wc -l)
    echo "  Total exchanges: $EXCHANGE_COUNT"
else
    echo -e "${RED}✗ Could not retrieve exchanges${NC}"
    exit 1
fi
echo ""

# Test 8: Check connections
echo -e "${YELLOW}8. Checking active connections...${NC}"
CONNECTIONS=$(curl -s -u ${RABBITMQ_USER}:${RABBITMQ_PASS} http://${RABBITMQ_HOST}:${RABBITMQ_MGMT_PORT}/api/connections)
if echo "$CONNECTIONS" | grep -q "\[\|{"; then
    echo -e "${GREEN}✓ Connection data retrieved${NC}"
    CONNECTION_COUNT=$(echo "$CONNECTIONS" | grep -o '"name"' | wc -l)
    echo "  Active connections: $CONNECTION_COUNT"
else
    echo -e "${RED}✗ Could not retrieve connection data${NC}"
fi
echo ""

# Test 9: Check plugins
echo -e "${YELLOW}9. Checking enabled plugins...${NC}"
PLUGINS=$(docker exec rabbitmq rabbitmqctl list_enabled_plugins 2>&1)
if echo "$PLUGINS" | grep -q "rabbitmq_management"; then
    echo -e "${GREEN}✓ Management plugin is enabled${NC}"
else
    echo -e "${RED}✗ Management plugin is NOT enabled${NC}"
    exit 1
fi
echo ""

# Summary
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    ✓ All tests passed!                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}RabbitMQ Information:${NC}"
echo "  Host:              ${RABBITMQ_HOST}"
echo "  AMQP Port:         ${RABBITMQ_PORT}"
echo "  Management Port:   ${RABBITMQ_MGMT_PORT}"
echo "  Username:          ${RABBITMQ_USER}"
echo ""
echo -e "${BLUE}Access URLs:${NC}"
echo "  AMQP:              amqp://${RABBITMQ_USER}:****@${RABBITMQ_HOST}:${RABBITMQ_PORT}/"
echo "  Management UI:     http://${RABBITMQ_HOST}:${RABBITMQ_MGMT_PORT}"
echo ""
echo -e "${BLUE}Useful Commands:${NC}"
echo "  View logs:         docker-compose logs -f rabbitmq"
echo "  Stop:              docker-compose down rabbitmq"
echo "  Status:            docker exec -it rabbitmq rabbitmqctl status"
echo "  List queues:       docker exec -it rabbitmq rabbitmqctl list_queues"
echo ""
