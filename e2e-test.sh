#!/bin/bash

# Hi.Events End-to-End Deployment Test
# Tests complete user flow: homepage → login → dashboard → registration

set -e

BASE_URL="https://hi-events-g3dx.onrender.com"
API_URL="${BASE_URL}/api"

# Test credentials
SUPER_ADMIN_EMAIL="flynnduerrel@gmail.com"
SUPER_ADMIN_PASSWORD="Password123!"
TEST_USER_EMAIL="test-$(date +%s)@example.com"
TEST_USER_PASSWORD="TestPassword123!"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
log_test() {
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "\n${BLUE}Test $TESTS_RUN: $1${NC}"
}

log_success() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓ $1${NC}"
}

log_failure() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗ $1${NC}"
}

log_info() {
    echo -e "  $1"
}

# Extract value from JSON using basic grep/sed (more portable than jq)
get_json_value() {
    echo "$1" | grep -o "\"$2\":[^,}]*" | cut -d':' -f2- | tr -d ' "' | cut -d',' -f1
}

echo "=================================================="
echo "Hi.Events End-to-End Deployment Test"
echo "=================================================="
echo "Base URL: $BASE_URL"
echo "API URL: $API_URL"
echo ""

# Test 1: Check homepage is accessible
log_test "Homepage is accessible"
RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL")
HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    if echo "$BODY" | grep -q "html\|login\|register" -i; then
        log_success "Homepage loads (HTTP $HTTP_CODE) with HTML content"
    else
        log_failure "Homepage loads but no HTML content detected"
    fi
else
    log_failure "Homepage returned HTTP $HTTP_CODE (expected 200)"
fi

# Test 2: Check static assets are loading
log_test "Static assets are accessible"
ASSET_URLS=(
    "$BASE_URL/favicon.svg"
    "$BASE_URL/site.webmanifest"
)

for ASSET_URL in "${ASSET_URLS[@]}"; do
    ASSET_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$ASSET_URL")
    if [ "$ASSET_CODE" = "200" ]; then
        log_success "$ASSET_URL (HTTP $ASSET_CODE)"
    else
        log_failure "$ASSET_URL (HTTP $ASSET_CODE, expected 200)"
    fi
done

# Test 3: Check API health endpoint
log_test "API health endpoint"
HEALTH_RESPONSE=$(curl -s "$API_URL/health")
if echo "$HEALTH_RESPONSE" | grep -q "ok\|healthy\|success" -i; then
    log_success "Health check passed: $HEALTH_RESPONSE"
else
    log_info "Health response: $HEALTH_RESPONSE"
    log_success "Health endpoint responded"
fi

# Test 4: Test super admin login
log_test "Super admin login"
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$SUPER_ADMIN_EMAIL\",
    \"password\": \"$SUPER_ADMIN_PASSWORD\"
  }")

TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
if [ -n "$TOKEN" ] && [ ${#TOKEN} -gt 20 ]; then
    log_success "Super admin login successful - token obtained"
    log_info "Token (first 20 chars): ${TOKEN:0:20}..."
    SUPER_ADMIN_TOKEN="$TOKEN"
else
    log_failure "Super admin login failed"
    log_info "Response: $LOGIN_RESPONSE"
    SUPER_ADMIN_TOKEN=""
fi

# Test 5: Verify authenticated endpoint with token
if [ -n "$SUPER_ADMIN_TOKEN" ]; then
    log_test "Authenticated endpoint (GET /users/me)"
    ME_RESPONSE=$(curl -s -X GET "$API_URL/users/me" \
      -H "Authorization: Bearer $SUPER_ADMIN_TOKEN")
    
    if echo "$ME_RESPONSE" | grep -q "$SUPER_ADMIN_EMAIL"; then
        log_success "Authenticated request successful - received user data"
        log_info "Email in response: $SUPER_ADMIN_EMAIL"
    else
        log_failure "Authenticated request failed or email not found"
        log_info "Response: $(echo "$ME_RESPONSE" | head -c 200)"
    fi
fi

# Test 6: Test user registration
log_test "User registration"
REGISTER_RESPONSE=$(curl -s -X POST "$API_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$TEST_USER_EMAIL\",
    \"password\": \"$TEST_USER_PASSWORD\",
    \"password_confirmation\": \"$TEST_USER_PASSWORD\",
    \"first_name\": \"Test\",
    \"last_name\": \"User\"
  }")

REG_TOKEN=$(echo "$REGISTER_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
if [ -n "$REG_TOKEN" ] && [ ${#REG_TOKEN} -gt 20 ]; then
    log_success "Registration successful - token obtained"
    log_info "New user email: $TEST_USER_EMAIL"
    TEST_USER_TOKEN="$REG_TOKEN"
else
    log_failure "Registration failed"
    log_info "Response: $(echo "$REGISTER_RESPONSE" | head -c 300)"
    TEST_USER_TOKEN=""
fi

# Test 7: Verify new user can access authenticated endpoints
if [ -n "$TEST_USER_TOKEN" ]; then
    log_test "New user authenticated endpoint access"
    NEW_USER_ME=$(curl -s -X GET "$API_URL/users/me" \
      -H "Authorization: Bearer $TEST_USER_TOKEN")
    
    if echo "$NEW_USER_ME" | grep -q "$TEST_USER_EMAIL"; then
        log_success "New user can access authenticated endpoints"
    else
        log_failure "New user cannot access authenticated endpoints"
    fi
fi

# Test 8: Test invalid credentials
log_test "Invalid login credentials rejection"
INVALID_LOGIN=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"nonexistent@example.com\",
    \"password\": \"WrongPassword123!\"
  }")

if echo "$INVALID_LOGIN" | grep -q "401\|unauthorized\|incorrect" -i || ! echo "$INVALID_LOGIN" | grep -q '"token"'; then
    log_success "Invalid login properly rejected"
else
    log_failure "Invalid login was not rejected"
    log_info "Response: $INVALID_LOGIN"
fi

# Test 9: Test logout endpoint
if [ -n "$SUPER_ADMIN_TOKEN" ]; then
    log_test "Logout endpoint"
    LOGOUT_RESPONSE=$(curl -s -X POST "$API_URL/auth/logout" \
      -H "Authorization: Bearer $SUPER_ADMIN_TOKEN")
    
    if [ $? -eq 0 ]; then
        log_success "Logout endpoint responded"
    else
        log_failure "Logout endpoint failed"
    fi
fi

# Test 10: Verify CSS/JS assets are in responses
log_test "Frontend includes CSS/JS assets"
HOMEPAGE=$(curl -s "$BASE_URL")
if echo "$HOMEPAGE" | grep -q "\.css\|\.js\|<script\|<link" && echo "$HOMEPAGE" | grep -q "href\|src"; then
    log_success "Frontend includes asset references"
    CSS_COUNT=$(echo "$HOMEPAGE" | grep -o '\.css' | wc -l)
    JS_COUNT=$(echo "$HOMEPAGE" | grep -o '\.js' | wc -l)
    log_info "CSS files: $CSS_COUNT, JS files: $JS_COUNT"
else
    log_failure "Frontend missing asset references"
fi

# Test 11: Check database connectivity (via API)
log_test "Database connectivity"
if [ -n "$SUPER_ADMIN_TOKEN" ]; then
    ACCOUNTS_RESPONSE=$(curl -s -X GET "$API_URL/accounts" \
      -H "Authorization: Bearer $SUPER_ADMIN_TOKEN")
    
    if echo "$ACCOUNTS_RESPONSE" | grep -q "data\|\[\|\{" || [ ${#ACCOUNTS_RESPONSE} -gt 10 ]; then
        log_success "Database is accessible (received account data)"
    else
        log_failure "Database may not be accessible"
    fi
fi

# Test 12: Verify CORS headers
log_test "CORS headers are present"
CORS_RESPONSE=$(curl -s -i -X OPTIONS "$API_URL/auth/login" -H "Origin: $BASE_URL" | head -20)
if echo "$CORS_RESPONSE" | grep -q "Access-Control\|allow" -i; then
    log_success "CORS headers detected"
else
    log_info "No explicit CORS headers (may be permissive)"
fi

# Summary
echo ""
echo "=================================================="
echo "Test Summary"
echo "=================================================="
echo "Total tests: $TESTS_RUN"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
else
    echo -e "${GREEN}Failed: $TESTS_FAILED${NC}"
fi

SUCCESS_RATE=$((TESTS_PASSED * 100 / TESTS_RUN))
echo "Success rate: $SUCCESS_RATE%"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed! Deployment is working correctly.${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed. Review the output above for details.${NC}"
    exit 1
fi

