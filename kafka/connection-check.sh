#
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "${YELLOW}Testing Kafka connection to 127.0.0.1...${NC}"

# Test external ports
echo "\nTesting External Ports:"
nc -z -v -w 5 127.0.0.1 9092 2>&1 && echo "${GREEN}✓ Successfully connected to Kafka00 at 127.0.0.1:9092${NC}" || echo "${RED}✗ Failed to connect to Kafka00 at 127.0.0.1:9092${NC}"
nc -z -v -w 5 127.0.0.1 9093 2>&1 && echo "${GREEN}✓ Successfully connected to Kafka01 at 127.0.0.1:9093${NC}" || echo "${RED}✗ Failed to connect to Kafka01 at 127.0.0.1:9093${NC}"

echo "\n${YELLOW}Application Configuration:${NC}"
echo "External applications should use these bootstrap servers:"
echo "${GREEN}bootstrap.servers=127.0.0.1:9092,127.0.0.1:9093${NC}"
