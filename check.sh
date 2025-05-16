#!/bin/bash

# Define colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Checking Kafka broker connection status...${NC}"

# Check if nc (netcat) is installed
if ! command -v nc &> /dev/null; then
    echo -e "${RED}Error: nc (netcat) is not installed. Please install it first.${NC}"
    exit 1
fi

# Check connections to Kafka brokers
check_broker() {
    local host=$1
    local port=$2
    local broker_name=$3

    echo -e "Checking connection to ${broker_name} at ${host}:${port}..."

    if nc -z -w 5 $host $port; then
        echo -e "${GREEN}✓ Successfully connected to ${broker_name} at ${host}:${port}${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to connect to ${broker_name} at ${host}:${port}${NC}"
        return 1
    fi
}

# Check if kafka-topics command is available
if command -v kafka-topics &> /dev/null; then
    echo -e "\n${YELLOW}Testing Kafka broker functionality:${NC}"

    # Try to list topics for broker 1
    echo -e "\nAttempting to list topics from broker 1 (localhost:9092):"
    if kafka-topics --bootstrap-server localhost:9092 --list; then
        echo -e "${GREEN}✓ Successfully listed topics from broker 1${NC}"
    else
        echo -e "${RED}✗ Failed to list topics from broker 1${NC}"
    fi

    # Try to list topics for broker 2
    echo -e "\nAttempting to list topics from broker 2 (localhost:9093):"
    if kafka-topics --bootstrap-server localhost:9093 --list; then
        echo -e "${GREEN}✓ Successfully listed topics from broker 2${NC}"
    else
        echo -e "${RED}✗ Failed to list topics from broker 2${NC}"
    fi
else
    echo -e "${YELLOW}Note: kafka-topics command not found. Only basic connectivity check performed.${NC}"
fi

# Main execution
echo -e "\n${YELLOW}Checking basic connectivity:${NC}"
broker1_status=0
broker2_status=0
broker1_external_status=0
broker2_external_status=0

check_broker "localhost" "9092" "Kafka Broker 1 (kafka00) - Internal Port" || broker1_status=1
check_broker "localhost" "9093" "Kafka Broker 2 (kafka01) - Internal Port" || broker2_status=1
check_broker "localhost" "19092" "Kafka Broker 1 (kafka00) - External Port" || broker1_external_status=1
check_broker "localhost" "19093" "Kafka Broker 2 (kafka01) - External Port" || broker2_external_status=1

# Summary
echo -e "\n${YELLOW}Connection Status Summary:${NC}"
if [ $broker1_external_status -eq 0 ] && [ $broker2_external_status -eq 0 ]; then
    echo -e "${GREEN}All Kafka brokers are reachable via external ports.${NC}"
elif [ $broker1_external_status -eq 0 ] || [ $broker2_external_status -eq 0 ]; then
    echo -e "${YELLOW}Warning: Some Kafka brokers are reachable via external ports.${NC}"
else
    echo -e "${RED}Error: No Kafka brokers are reachable via external ports.${NC}"
fi

if [ $broker1_status -eq 0 ] && [ $broker2_status -eq 0 ]; then
    echo -e "${GREEN}All Kafka brokers are reachable via internal ports.${NC}"
elif [ $broker1_status -eq 0 ] || [ $broker2_status -eq 0 ]; then
    echo -e "${YELLOW}Warning: Some Kafka brokers are reachable via internal ports.${NC}"
else
    echo -e "${RED}Error: No Kafka brokers are reachable via internal ports.${NC}"
fi

# Return success if at least the external ports are working
exit $(($broker1_external_status && $broker2_external_status))
