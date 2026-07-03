#!/bin/bash

# Script to generate SHA256 hash for ClickHouse password

if [ -z "$1" ]; then
    echo "Usage: ./generate_password.sh <your_password>"
    echo ""
    echo "Example: ./generate_password.sh mypassword123"
    exit 1
fi

PASSWORD="$1"

echo "==================================="
echo "ClickHouse Password Generator"
echo "==================================="
echo ""
echo "Your password: $PASSWORD"
echo ""

# Generate SHA256 hash
HASH=$(echo -n "$PASSWORD" | sha256sum 2>/dev/null || echo -n "$PASSWORD" | shasum -a 256)
HASH=$(echo "$HASH" | awk '{print $1}')

echo "SHA256 Hash: $HASH"
echo ""
echo "Add these lines to your .env file:"
echo "-----------------------------------"
echo "CLICKHOUSE_PASSWORD=$PASSWORD"
echo "CLICKHOUSE_PASSWORD_SHA256=$HASH"
echo "CLICKHOUSE_USER_PASSWORD_SHA256=$HASH"
echo ""
