#!/bin/bash

# Hi.Events API Endpoint Tester
# Tests the login and registration endpoints

API_URL="https://hi-events-g3dx.onrender.com/api"
EMAIL="flynnduerrel@gmail.com"
PASSWORD="Password123!"

echo "=================================================="
echo "Hi.Events API Endpoint Tester"
echo "=================================================="
echo ""

# Test 1: Check if API is reachable
echo "Test 1: Checking API connectivity..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${API_URL}/health")
echo "  GET ${API_URL}/health -> HTTP $HTTP_CODE"
echo ""

# Test 2: Check the status endpoint
echo "Test 2: Checking API status endpoint..."
curl -s -X GET "${API_URL}/status" | jq . || echo "  Status endpoint returned non-JSON"
echo ""

# Test 3: Test login endpoint with valid credentials
echo "Test 3: Testing login endpoint with valid credentials..."
LOGIN_RESPONSE=$(curl -s -X POST "${API_URL}/auth/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"${EMAIL}\",
    \"password\": \"${PASSWORD}\"
  }")

echo "  Response:"
echo "$LOGIN_RESPONSE" | jq . || echo "$LOGIN_RESPONSE"
echo ""

# Extract token if login successful
TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token // empty' 2>/dev/null)
if [ -n "$TOKEN" ]; then
    echo "✓ Login successful! Token obtained."
    echo ""
    
    # Test 4: Test authenticated endpoint
    echo "Test 4: Testing authenticated endpoint (GET /api/users/me)..."
    curl -s -X GET "${API_URL}/users/me" \
      -H "Authorization: Bearer ${TOKEN}" | jq . || echo "  Response received"
    echo ""
else
    echo "✗ Login failed or token not found in response"
    echo ""
fi

# Test 5: Test registration endpoint (will fail if user exists, but we can see the response)
echo "Test 5: Testing registration endpoint..."
TEST_EMAIL="test-$(date +%s)@example.com"
REGISTER_RESPONSE=$(curl -s -X POST "${API_URL}/auth/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"${TEST_EMAIL}\",
    \"password\": \"TestPassword123!\",
    \"first_name\": \"Test\",
    \"last_name\": \"User\"
  }")

echo "  Response:"
echo "$REGISTER_RESPONSE" | jq . || echo "$REGISTER_RESPONSE"
echo ""

echo "=================================================="
echo "Testing complete!"
echo "=================================================="

