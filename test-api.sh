#!/bin/bash

# =====================================================
# Multi-Product Learning API - Complete Test Script
# =====================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# API Base URL
API_URL="${API_URL:-http://localhost:3000}"

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Global variables for tokens
ACCESS_TOKEN=""
REFRESH_TOKEN=""
USER_ID=""
ADMIN_ACCESS_TOKEN=""
PRODUCT_ID=""
TOPIC_ID=""
QNA_ID=""
QUIZ_ID=""
PDF_ID=""

# =====================================================
# Helper Functions
# =====================================================

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_test() {
    echo -e "${YELLOW}TEST: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ PASS: $1${NC}\n"
    ((PASSED_TESTS++))
    ((TOTAL_TESTS++))
}

print_failure() {
    echo -e "${RED}✗ FAIL: $1${NC}"
    echo -e "${RED}Response: $2${NC}\n"
    ((FAILED_TESTS++))
    ((TOTAL_TESTS++))
}

test_endpoint() {
    local method=$1
    local endpoint=$2
    local data=$3
    local expected_status=$4
    local auth_header=$5
    
    if [ -n "$auth_header" ]; then
        response=$(curl -s -w "\n%{http_code}" -X $method \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $auth_header" \
            -d "$data" \
            "$API_URL$endpoint")
    else
        response=$(curl -s -w "\n%{http_code}" -X $method \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$API_URL$endpoint")
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    echo "$body" | jq '.' 2>/dev/null || echo "$body"
    
    if [ "$http_code" == "$expected_status" ]; then
        return 0
    else
        echo -e "${RED}Expected status: $expected_status, Got: $http_code${NC}"
        return 1
    fi
}

# =====================================================
# Test: Server Health
# =====================================================

test_server_health() {
    print_header "1. SERVER HEALTH CHECKS"
    
    print_test "Testing root endpoint"
    if test_endpoint "GET" "/" "" "200"; then
        print_success "Root endpoint accessible"
    else
        print_failure "Root endpoint failed" "$response"
    fi
    
    print_test "Testing health endpoint"
    if test_endpoint "GET" "/health" "" "200"; then
        print_success "Health endpoint working"
    else
        print_failure "Health endpoint failed" "$response"
    fi
    
    print_test "Testing API docs endpoint"
    response=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/api-docs/")
    if [ "$response" == "200" ] || [ "$response" == "301" ]; then
        print_success "API documentation accessible"
        ((TOTAL_TESTS++))
        ((PASSED_TESTS++))
    else
        print_failure "API docs not accessible" "Status: $response"
    fi
}

# =====================================================
# Test: Authentication
# =====================================================

test_authentication() {
    print_header "2. AUTHENTICATION TESTS"
    
    # Generate random email for testing
    TEST_EMAIL="testuser_$(date +%s)@example.com"
    TEST_PASSWORD="TestPass123!"
    
    # Test Registration
    print_test "User Registration"
    response=$(curl -s -X POST "$API_URL/api/v1/auth/register" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"Test User\",
            \"email\": \"$TEST_EMAIL\",
            \"password\": \"$TEST_PASSWORD\"
        }")
    
    if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
        ACCESS_TOKEN=$(echo "$response" | jq -r '.data.accessToken')
        REFRESH_TOKEN=$(echo "$response" | jq -r '.data.refreshToken')
        USER_ID=$(echo "$response" | jq -r '.data.user.id')
        print_success "User registered successfully"
        echo "User ID: $USER_ID"
    else
        print_failure "Registration failed" "$response"
    fi
    
    # Test Duplicate Registration
    print_test "Duplicate Registration (should fail)"
    response=$(curl -s -X POST "$API_URL/api/v1/auth/register" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"Test User\",
            \"email\": \"$TEST_EMAIL\",
            \"password\": \"$TEST_PASSWORD\"
        }")
    
    if echo "$response" | jq -e '.success == false' > /dev/null 2>&1; then
        print_success "Duplicate registration correctly rejected"
    else
        print_failure "Duplicate registration should have failed" "$response"
    fi
    
    # Test Login
    print_test "User Login"
    response=$(curl -s -X POST "$API_URL/api/v1/auth/login" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"$TEST_EMAIL\",
            \"password\": \"$TEST_PASSWORD\"
        }")
    
    if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
        ACCESS_TOKEN=$(echo "$response" | jq -r '.data.accessToken')
        REFRESH_TOKEN=$(echo "$response" | jq -r '.data.refreshToken')
        print_success "Login successful"
    else
        print_failure "Login failed" "$response"
    fi
    
    # Test Invalid Login
    print_test "Invalid Login (should fail)"
    response=$(curl -s -X POST "$API_URL/api/v1/auth/login" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"$TEST_EMAIL\",
            \"password\": \"WrongPassword123\"
        }")
    
    if echo "$response" | jq -e '.success == false' > /dev/null 2>&1; then
        print_success "Invalid login correctly rejected"
    else
        print_failure "Invalid login should have failed" "$response"
    fi
    
    # Test Token Refresh
    print_test "Token Refresh"
    response=$(curl -s -X POST "$API_URL/api/v1/auth/refresh" \
        -H "Content-Type: application/json" \
        -d "{\"refreshToken\": \"$REFRESH_TOKEN\"}")
    
    if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
        NEW_ACCESS_TOKEN=$(echo "$response" | jq -r '.data.accessToken')
        ACCESS_TOKEN=$NEW_ACCESS_TOKEN
        print_success "Token refresh successful"
    else
        print_failure "Token refresh failed" "$response"
    fi
    
    # Test Protected Route Without Token
    print_test "Access protected route without token (should fail)"
    response=$(curl -s -X GET "$API_URL/api/v1/users/profile")
    
    if echo "$response" | jq -e '.success == false' > /dev/null 2>&1; then
        print_success "Unauthorized access correctly blocked"
    else
        print_failure "Should have blocked unauthorized access" "$response"
    fi
}

# =====================================================
# Test: User Endpoints
# =====================================================

test_user_endpoints() {
    print_header "3. USER ENDPOINT TESTS"
    
    # Test Get Profile
    print_test "Get User Profile"
    response=$(curl -s -X GET "$API_URL/api/v1/users/profile" \
        -H "Authorization: Bearer $ACCESS_TOKEN")
    
    if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
        print_success "Profile retrieved successfully"
    else
        print_failure "Failed to get profile" "$response"
    fi
    
    # Test Update Profile
    print_test "Update User Profile"
    response=$(curl -s -X PUT "$API_URL/api/v1/users/profile" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"name": "Updated Test User"}')
    
    if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
        print_success "Profile updated successfully"
    else
        print_failure "Failed to update profile" "$response"
    fi
    
    # Test Get User Stats
    print_test "Get User Statistics"
    response=$(curl -s -X GET "$API_URL/api/v1/users/stats" \
        -H "Authorization: Bearer $ACCESS_TOKEN")
    
    if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
        print_success "Statistics retrieved successfully"
    else
        print_failure "Failed to get statistics" "$response"
    fi
    
    # Test Get Progress
    print_test "Get User Progress"
    response=$(curl -s -X GET "$API_URL/api/v1/users/progress" \
        -H "Authorization: Bearer $ACCESS_TOKEN")
    
    if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
        print_success "Progress retrieved successfully"
    else
        print_failure "Failed to get progress" "$response"
    fi
}

# =====================================================
# Test: Product Endpoints
# =====================================================

test_product_endpoints() {
    print_header "4. PRODUCT ENDPOINT TESTS"
    
    # Test Get All Products
    print_test "Get All Products"
    response=$(curl -s -X GET "$API_URL/api/v1/products")
    
    if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
        PRODUCT_ID=$(echo "$response" | jq -r '.data[0].id')
        print_success "Products retrieved successfully"
        echo "Product ID: $PRODUCT_ID"
    else
        print_failure "Failed to get products" "$response"
    fi
    
    # Test Get Product Topics
    if [ -n "$PRODUCT_ID" ]; then
        print_test "Get Product Topics"
        response=$(curl -s -X GET "$API_URL/api/v1/products/$PRODUCT_ID/topics")
        
        if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
            TOPIC_ID=$(echo "$response" | jq -r '.data[0].id')
            print_success "Topics retrieved successfully"
            echo "Topic ID: $TOPIC_ID"
        else
            print_failure "Failed to get topics" "$response"
        fi
    fi
    
    # Test Get Q&A
    if [ -n "$PRODUCT_ID" ]; then
        print_test "Get Q&A for Product"
        response=$(curl -s -X GET "$API_URL/api/v1/products/$PRODUCT_ID/qna" \
            -H "Authorization: Bearer $ACCESS_TOKEN")
        
        if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
            QNA_ID=$(echo "$response" | jq -r '.data[0].id')
            print_success "Q&A retrieved successfully"
            echo "Q&A ID: $QNA_ID"
        else
            print_failure "Failed to get Q&A" "$response"
        fi
    fi
    
    # Test Get Q&A with Company Filter
    if [ -n "$PRODUCT_ID" ]; then
        print_test "Get Q&A filtered by Company (Amazon)"
        response=$(curl -s -X GET "$API_URL/api/v1/products/$PRODUCT_ID/qna?company=amazon" \
            -H "Authorization: Bearer $ACCESS_TOKEN")
        
        if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
            print_success "Company-filtered Q&A retrieved successfully"
        else
            print_failure "Failed to get filtered Q&A" "$response"
        fi
    fi
    
    # Test Get Quizzes
    if [ -n "$PRODUCT_ID" ]; then
        print_test "Get Quizzes for Product"
        response=$(curl -s -X GET "$API_URL/api/v1/products/$PRODUCT_ID/quizzes" \
            -H "Authorization: Bearer $ACCESS_TOKEN")
        
        if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
            QUIZ_ID=$(echo "$response" | jq -r '.data[0].id')
            print_success "Quizzes retrieved successfully"
            echo "Quiz ID: $QUIZ_ID"
        else
            print_failure "Failed to get quizzes" "$response"
        fi
    fi
    
    # Test Get Quizzes with Filters
    if [ -n "$PRODUCT_ID" ]; then
        print_test "Get Quizzes with multiple filters"
        response=$(curl -s -X GET "$API_URL/api/v1/products/$PRODUCT_ID/quizzes?company=google&level=intermediate&limit=5" \
            -H "Authorization: Bearer $ACCESS_TOKEN")
        
        if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
            print_success "Filtered quizzes retrieved successfully"
        else
            print_failure "Failed to get filtered quizzes" "$response"
        fi
    fi
    
    # Test Submit Quiz Answer
    if [ -n "$PRODUCT_ID" ] && [ -n "$QUIZ_ID" ]; then
        print_test "Submit Quiz Answer"
        response=$(curl -s -X POST "$API_URL/api/v1/products/$PRODUCT_ID/quizzes/$QUIZ_ID/submit" \
            -H "Authorization: Bearer $ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            -d '{"selectedAnswer": "Array", "timeTaken": 30}')
        
        if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
            print_success "Quiz answer submitted successfully"
        else
            print_failure "Failed to submit quiz answer" "$response"
        fi
    fi
    
    # Test Get PDFs
    if [ -n "$PRODUCT_ID" ]; then
        print_test "Get PDFs for Product"
        response=$(curl -s -X GET "$API_URL/api/v1/products/$PRODUCT_ID/pdfs" \
            -H "Authorization: Bearer $ACCESS_TOKEN")
        
        if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
            PDF_ID=$(echo "$response" | jq -r '.data[0].id')
            print_success "PDFs retrieved successfully"
            echo "PDF ID: $PDF_ID"
        else
            print_failure "Failed to get PDFs" "$response"
        fi
    fi
}

# =====================================================
# Test: Bookmark Endpoints
# =====================================================

test_bookmark_endpoints() {
    print_header "5. BOOKMARK TESTS"
    
    # Test Add Q&A Bookmark
    if [ -n "$QNA_ID" ]; then
        print_test "Add Q&A Bookmark"
        response=$(curl -s -X POST "$API_URL/api/v1/users/bookmarks" \
            -H "Authorization: Bearer $ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{\"qnaId\": \"$QNA_ID\"}")
        
        if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
            BOOKMARK_ID=$(echo "$response" | jq -r '.data.id')
            print_success "Q&A bookmarked successfully"
        else
            print_failure "Failed to add Q&A bookmark" "$response"
        fi
    fi
    
    # Test Add PDF Bookmark
    if [ -n "$PDF_ID" ]; then
        print_test "Add PDF Bookmark"
        response=$(curl -s -X POST "$API_URL/api/v1/users/bookmarks" \
            -H "Authorization: Bearer $ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{\"pdfId\": \"$PDF_ID\"}")
        
        if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
            print_success "PDF bookmarked successfully"
        else
            print_failure "Failed to add PDF bookmark" "$response"
        fi
    fi
    
    # Test Get Bookmarks
    print_test "Get All Bookmarks"
    response=$(curl -s -X GET "$API_URL/api/v1/users/bookmarks" \
        -H "Authorization: Bearer $ACCESS_TOKEN")
    
    if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
        print_success "Bookmarks retrieved successfully"
    else
        print_failure "Failed to get bookmarks" "$response"
    fi
    
    # Test Remove Bookmark
    if [ -n "$BOOKMARK_ID" ]; then
        print_test "Remove Bookmark"
        response=$(curl -s -X DELETE "$API_URL/api/v1/users/bookmarks/$BOOKMARK_ID" \
            -H "Authorization: Bearer $ACCESS_TOKEN")
        
        if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
            print_success "Bookmark removed successfully"
        else
            print_failure "Failed to remove bookmark" "$response"
        fi
    fi
}

# =====================================================
# Test: Progress Tracking
# =====================================================

test_progress_tracking() {
    print_header "6. PROGRESS TRACKING TESTS"
    
    if [ -n "$TOPIC_ID" ]; then
        # Test Update Progress
        print_test "Update Topic Progress"
        response=$(curl -s -X POST "$API_URL/api/v1/users/progress" \
            -H "Authorization: Bearer $ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{
                \"topicId\": \"$TOPIC_ID\",
                \"completionPercent\": 75,
                \"score\": 85.5
            }")
        
        if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
            print_success "Progress updated successfully"
        else
            print_failure "Failed to update progress" "$response"
        fi
        
        # Test Get Progress Again
        print_test "Verify Progress Update"
        response=$(curl -s -X GET "$API_URL/api/v1/users/progress" \
            -H "Authorization: Bearer $ACCESS_TOKEN")
        
        if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
            print_success "Updated progress verified"
        else
            print_failure "Failed to verify progress" "$response"
        fi
    fi
}

# =====================================================
# Test: Admin Endpoints (Login as Admin First)
# =====================================================

test_admin_endpoints() {
    print_header "7. ADMIN ENDPOINT TESTS"
    
    # Login as Master Admin
    print_test "Login as Master Admin"
    response=$(curl -s -X POST "$API_URL/api/v1/auth/login" \
        -H "Content-Type: application/json" \
        -d '{
            "email": "admin@example.com",
            "password": "Admin123!"
        }')
    
    if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
        ADMIN_ACCESS_TOKEN=$(echo "$response" | jq -r '.data.accessToken')
        print_success "Admin login successful"
    else
        print_failure "Admin login failed - skipping admin tests" "$response"
        return
    fi
    
    # Test Get All Products (Admin)
    print_test "Admin: Get All Products"
    response=$(curl -s -X GET "$API_URL/api/v1/admin/products" \
        -H "Authorization: Bearer $ADMIN_ACCESS_TOKEN")
    
    if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
        print_success "Admin retrieved products"
    else
        print_failure "Admin failed to get products" "$response"
    fi
    
    # Test Create Product
    print_test "Admin: Create New Product"
    NEW_PRODUCT_SLUG="test-product-$(date +%s)"
    response=$(curl -s -X POST "$API_URL/api/v1/admin/products" \
        -H "Authorization: Bearer $ADMIN_ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"Test Product\",
            \"slug\": \"$NEW_PRODUCT_SLUG\",
            \"description\": \"A test product for automated testing\"
        }")
    
    if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
        NEW_PRODUCT_ID=$(echo "$response" | jq -r '.data.id')
        print_success "Product created successfully"
    else
        print_failure "Failed to create product" "$response"
    fi
    
    # Test Create Topic
    if [ -n "$NEW_PRODUCT_ID" ]; then
        print_test "Admin: Create New Topic"
        response=$(curl -s -X POST "$API_URL/api/v1/admin/topics" \
            -H "Authorization: Bearer $ADMIN_ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{
                \"productId\": \"$NEW_PRODUCT_ID\",
                \"name\": \"Test Topic\",
                \"description\": \"A test topic\",
                \"order\": 1
            }")
        
        if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
            NEW_TOPIC_ID=$(echo "$response" | jq -r '.data.id')
            print_success "Topic created successfully"
        else
            print_failure "Failed to create topic" "$response"
        fi
    fi
    
    # Test Create Q&A
    if [ -n "$NEW_TOPIC_ID" ]; then
        print_test "Admin: Create New Q&A"
        response=$(curl -s -X POST "$API_URL/api/v1/admin/qna" \
            -H "Authorization: Bearer $ADMIN_ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{
                \"topicId\": \"$NEW_TOPIC_ID\",
                \"question\": \"What is a test question?\",
                \"answer\": \"This is a test answer for automated testing.\",
                \"level\": \"BEGINNER\",
                \"companyTags\": [\"TestCorp\", \"Example Inc\"]
            }")
        
        if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
            print_success "Q&A created successfully"
        else
            print_failure "Failed to create Q&A" "$response"
        fi
    fi
    
    # Test Create Quiz
    if [ -n "$NEW_TOPIC_ID" ]; then
        print_test "Admin: Create New Quiz"
        response=$(curl -s -X POST "$API_URL/api/v1/admin/quizzes" \
            -H "Authorization: Bearer $ADMIN_ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{
                \"topicId\": \"$NEW_TOPIC_ID\",
                \"question\": \"What is 2 + 2?\",
                \"options\": [\"3\", \"4\", \"5\", \"6\"],
                \"correctAnswer\": \"4\",
                \"explanation\": \"Basic arithmetic\",
                \"level\": \"BEGINNER\",
                \"companyTags\": [\"TestCorp\"]
            }")
        
        if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
            print_success "Quiz created successfully"
        else
            print_failure "Failed to create quiz" "$response"
        fi
    fi
    
    # Test Get Analytics
    print_test "Admin: Get Analytics"
    response=$(curl -s -X GET "$API_URL/api/v1/admin/analytics" \
        -H "Authorization: Bearer $ADMIN_ACCESS_TOKEN")
    
    if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
        print_success "Analytics retrieved successfully"
    else
        print_failure "Failed to get analytics" "$response"
    fi
    
    # Test User Cannot Access Admin Routes
    print_test "Regular User Cannot Access Admin Routes (should fail)"
    response=$(curl -s -X GET "$API_URL/api/v1/admin/products" \
        -H "Authorization: Bearer $ACCESS_TOKEN")
    
    if echo "$response" | jq -e '.success == false' > /dev/null 2>&1; then
        print_success "Admin access correctly restricted"
    else
        print_failure "Regular user should not access admin routes" "$response"
    fi
}

# =====================================================
# Test: Error Handling
# =====================================================

test_error_handling() {
    print_header "8. ERROR HANDLING TESTS"
    
    # Test 404 Endpoint
    print_test "Test Non-existent Endpoint (404)"
    response=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/api/v1/nonexistent")
    if [ "$response" == "404" ]; then
        print_success "404 error correctly returned"
        ((TOTAL_TESTS++))
        ((PASSED_TESTS++))
    else
        print_failure "Expected 404, got $response" ""
    fi
    
    # Test Invalid JSON
    print_test "Test Invalid JSON Input"
    response=$(curl -s -X POST "$API_URL/api/v1/auth/register" \
        -H "Content-Type: application/json" \
        -d '{invalid json}')
    
    if echo "$response" | grep -q "error\|invalid" > /dev/null 2>&1; then
        print_success "Invalid JSON correctly rejected"
        ((TOTAL_TESTS++))
        ((PASSED_TESTS++))
    else
        print_failure "Should reject invalid JSON" "$response"
    fi
    
    # Test Missing Required Fields
    print_test "Test Missing Required Fields"
    response=$(curl -s -X POST "$API_URL/api/v1/auth/register" \
        -H "Content-Type: application/json" \
        -d '{"email": "test@test.com"}')
    
    if echo "$response" | jq -e '.success == false' > /dev/null 2>&1; then
        print_success "Missing fields correctly rejected"
    else
        print_failure "Should reject missing fields" "$response"
    fi
}

# =====================================================
# Test: Logout
# =====================================================

test_logout() {
    print_header "9. LOGOUT TEST"
    
    print_test "User Logout"
    response=$(curl -s -X POST "$API_URL/api/v1/auth/logout" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"refreshToken\": \"$REFRESH_TOKEN\"}")
    
    if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
        print_success "Logout successful"
    else
        print_failure "Logout failed" "$response"
    fi
}

# =====================================================
# Main Test Execution
# =====================================================

main() {
    clear
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║   🧪 Multi-Product Learning API - Test Suite              ║"
    echo "║                                                            ║"
    echo "║   Testing API at: $API_URL"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
    
    # Check if server is running
    if ! curl -s "$API_URL/health" > /dev/null 2>&1; then
        echo -e "${RED}ERROR: API server is not running at $API_URL${NC}"
        echo "Please start the server with: npm run dev"
        exit 1
    fi
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}ERROR: jq is not installed${NC}"
        echo "Please install jq: sudo apt-get install jq (Ubuntu) or brew install jq (Mac)"
        exit 1
    fi
    
    START_TIME=$(date +%s)
    
    # Run all tests
    test_server_health
    test_authentication
    test_user_endpoints
    test_product_endpoints
    test_bookmark_endpoints
    test_progress_tracking
    test_admin_endpoints
    test_error_handling
    test_logout
    
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    # Print Summary
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}TEST SUMMARY${NC}"
    echo -e "${BLUE}========================================${NC}\n"
    
    echo -e "Total Tests: ${TOTAL_TESTS}"
    echo -e "${GREEN}Passed: ${PASSED_TESTS}${NC}"
    echo -e "${RED}Failed: ${FAILED_TESTS}${NC}"
    echo -e "Duration: ${DURATION}s\n"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}✓ ALL TESTS PASSED! 🎉${NC}\n"
        exit 0
    else
        echo -e "${RED}✗ SOME TESTS FAILED${NC}\n"
        exit 1
    fi
}

# Run main function
main