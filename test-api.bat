param(
    [string]$ApiUrl = "http://localhost:3000"
)

# Test counters
$script:TotalTests = 0
$script:PassedTests = 0
$script:FailedTests = 0

# Global variables
$script:AccessToken = ""
$script:RefreshToken = ""
$script:UserId = ""
$script:ProductId = ""
$script:TopicId = ""
$script:QnaId = ""
$script:QuizId = ""

# Color functions
function Write-Header {
    param([string]$Text)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
}

function Write-Test {
    param([string]$Text)
    Write-Host "TEST: $Text" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Text)
    Write-Host "✓ PASS: $Text`n" -ForegroundColor Green
    $script:PassedTests++
    $script:TotalTests++
}

function Write-Failure {
    param([string]$Text, [string]$Response = "")
    Write-Host "✗ FAIL: $Text" -ForegroundColor Red
    if ($Response) {
        Write-Host "Response: $Response`n" -ForegroundColor Red
    }
    $script:FailedTests++
    $script:TotalTests++
}

# Test endpoint function
function Test-Endpoint {
    param(
        [string]$Method,
        [string]$Endpoint,
        [object]$Body = $null,
        [int]$ExpectedStatus = 200,
        [string]$Token = ""
    )
    
    try {
        $headers = @{
            "Content-Type" = "application/json"
        }
        
        if ($Token) {
            $headers["Authorization"] = "Bearer $Token"
        }
        
        $params = @{
            Uri = "$ApiUrl$Endpoint"
            Method = $Method
            Headers = $headers
            ContentType = "application/json"
        }
        
        if ($Body) {
            $params["Body"] = ($Body | ConvertTo-Json -Depth 10)
        }
        
        $response = Invoke-RestMethod @params -StatusCodeVariable statusCode
        
        return @{
            Success = $true
            StatusCode = $statusCode
            Data = $response
        }
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        return @{
            Success = $false
            StatusCode = $statusCode
            Error = $_.Exception.Message
        }
    }
}

# =====================================================
# Test Functions
# =====================================================

function Test-ServerHealth {
    Write-Header "1. SERVER HEALTH CHECKS"
    
    Write-Test "Testing root endpoint"
    $result = Test-Endpoint -Method "GET" -Endpoint "/"
    if ($result.Success -and $result.Data.success) {
        Write-Success "Root endpoint accessible"
    }
    else {
        Write-Failure "Root endpoint failed" $result.Error
    }
    
    Write-Test "Testing health endpoint"
    $result = Test-Endpoint -Method "GET" -Endpoint "/health"
    if ($result.Success -and $result.Data.status -eq "healthy") {
        Write-Success "Health endpoint working"
    }
    else {
        Write-Failure "Health endpoint failed" $result.Error
    }
    
    Write-Test "Testing API docs endpoint"
    try {
        $response = Invoke-WebRequest -Uri "$ApiUrl/api-docs/" -Method GET -UseBasicParsing
        if ($response.StatusCode -eq 200 -or $response.StatusCode -eq 301) {
            Write-Success "API documentation accessible"
        }
        else {
            Write-Failure "API docs not accessible"
        }
    }
    catch {
        Write-Failure "API docs not accessible" $_.Exception.Message
    }
}

function Test-Authentication {
    Write-Header "2. AUTHENTICATION TESTS"
    
    # Generate random email
    $timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $testEmail = "testuser_$timestamp@example.com"
    $testPassword = "TestPass123!"
    
    Write-Test "User Registration"
    $body = @{
        name = "Test User"
        email = $testEmail
        password = $testPassword
    }
    
    $result = Test-Endpoint -Method "POST" -Endpoint "/api/v1/auth/register" -Body $body -ExpectedStatus 201
    if ($result.Success -and $result.Data.success) {
        $script:AccessToken = $result.Data.data.accessToken
        $script:RefreshToken = $result.Data.data.refreshToken
        $script:UserId = $result.Data.data.user.id
        Write-Success "User registered successfully"
        Write-Host "  User ID: $script:UserId" -ForegroundColor Gray
    }
    else {
        Write-Failure "Registration failed" $result.Error
    }
    
    Write-Test "Duplicate Registration (should fail)"
    $result = Test-Endpoint -Method "POST" -Endpoint "/api/v1/auth/register" -Body $body
    if ($result.StatusCode -eq 400) {
        Write-Success "Duplicate registration correctly rejected"
    }
    else {
        Write-Failure "Duplicate registration should have failed"
    }
    
    Write-Test "User Login"
    $loginBody = @{
        email = $testEmail
        password = $testPassword
    }
    
    $result = Test-Endpoint -Method "POST" -Endpoint "/api/v1/auth/login" -Body $loginBody
    if ($result.Success -and $result.Data.success) {
        $script:AccessToken = $result.Data.data.accessToken
        $script:RefreshToken = $result.Data.data.refreshToken
        Write-Success "Login successful"
    }
    else {
        Write-Failure "Login failed" $result.Error
    }
    
    Write-Test "Invalid Login (should fail)"
    $invalidLogin = @{
        email = $testEmail
        password = "WrongPassword123"
    }
    
    $result = Test-Endpoint -Method "POST" -Endpoint "/api/v1/auth/login" -Body $invalidLogin
    if ($result.StatusCode -eq 401) {
        Write-Success "Invalid login correctly rejected"
    }
    else {
        Write-Failure "Invalid login should have failed"
    }
    
    Write-Test "Token Refresh"
    $refreshBody = @{
        refreshToken = $script:RefreshToken
    }
    
    $result = Test-Endpoint -Method "POST" -Endpoint "/api/v1/auth/refresh" -Body $refreshBody
    if ($result.Success -and $result.Data.success) {
        $script:AccessToken = $result.Data.data.accessToken
        Write-Success "Token refresh successful"
    }
    else {
        Write-Failure "Token refresh failed" $result.Error
    }
    
    Write-Test "Access protected route without token (should fail)"
    $result = Test-Endpoint -Method "GET" -Endpoint "/api/v1/users/profile"
    if ($result.StatusCode -eq 401) {
        Write-Success "Unauthorized access correctly blocked"
    }
    else {
        Write-Failure "Should have blocked unauthorized access"
    }
}

function Test-UserEndpoints {
    Write-Header "3. USER ENDPOINT TESTS"
    
    Write-Test "Get User Profile"
    $result = Test-Endpoint -Method "GET" -Endpoint "/api/v1/users/profile" -Token $script:AccessToken
    if ($result.Success -and $result.Data.success) {
        Write-Success "Profile retrieved successfully"
    }
    else {
        Write-Failure "Failed to get profile" $result.Error
    }
    
    Write-Test "Update User Profile"
    $body = @{
        name = "Updated Test User"
    }
    
    $result = Test-Endpoint -Method "PUT" -Endpoint "/api/v1/users/profile" -Body $body -Token $script:AccessToken
    if ($result.Success -and $result.Data.success) {
        Write-Success "Profile updated successfully"
    }
    else {
        Write-Failure "Failed to update profile" $result.Error
    }
    
    Write-Test "Get User Statistics"
    $result = Test-Endpoint -Method "GET" -Endpoint "/api/v1/users/stats" -Token $script:AccessToken
    if ($result.Success -and $result.Data.success) {
        Write-Success "Statistics retrieved successfully"
    }
    else {
        Write-Failure "Failed to get statistics" $result.Error
    }
    
    Write-Test "Get User Progress"
    $result = Test-Endpoint -Method "GET" -Endpoint "/api/v1/users/progress" -Token $script:AccessToken
    if ($result.Success -and $result.Data.success) {
        Write-Success "Progress retrieved successfully"
    }
    else {
        Write-Failure "Failed to get progress" $result.Error
    }
}

function Test-ProductEndpoints {
    Write-Header "4. PRODUCT ENDPOINT TESTS"
    
    Write-Test "Get All Products"
    $result = Test-Endpoint -Method "GET" -Endpoint "/api/v1/products"
    if ($result.Success -and $result.Data.success) {
        if ($result.Data.data.Count -gt 0) {
            $script:ProductId = $result.Data.data[0].id
            Write-Success "Products retrieved successfully"
            Write-Host "  Product ID: $script:ProductId" -ForegroundColor Gray
        }
        else {
            Write-Failure "No products found"
        }
    }
    else {
        Write-Failure "Failed to get products" $result.Error
    }
    
    if ($script:ProductId) {
        Write-Test "Get Product Topics"
        $result = Test-Endpoint -Method "GET" -Endpoint "/api/v1/products/$script:ProductId/topics"
        if ($result.Success -and $result.Data.success) {
            if ($result.Data.data.Count -gt 0) {
                $script:TopicId = $result.Data.data[0].id
                Write-Success "Topics retrieved successfully"
                Write-Host "  Topic ID: $script:TopicId" -ForegroundColor Gray
            }
        }
        else {
            Write-Failure "Failed to get topics" $result.Error
        }
        
        Write-Test "Get Q&A for Product"
        $result = Test-Endpoint -Method "GET" -Endpoint "/api/v1/products/$script:ProductId/qna" -Token $script:AccessToken
        if ($result.Success -and $result.Data.success) {
            if ($result.Data.data.Count -gt 0) {
                $script:QnaId = $result.Data.data[0].id
                Write-Success "Q&A retrieved successfully"
            }
            else {
                Write-Success "Q&A endpoint working (no data)"
            }
        }
        else {
            Write-Failure "Failed to get Q&A" $result.Error
        }
        
        Write-Test "Get Q&A filtered by Company (Amazon)"
        $result = Test-Endpoint -Method "GET" -Endpoint "/api/v1/products/$script:ProductId/qna?company=amazon" -Token $script:AccessToken
        if ($result.Success -and $result.Data.success) {
            Write-Success "Company-filtered Q&A retrieved successfully"
        }
        else {
            Write-Failure "Failed to get filtered Q&A" $result.Error
        }
        
        Write-Test "Get Quizzes for Product"
        $result = Test-Endpoint -Method "GET" -Endpoint "/api/v1/products/$script:ProductId/quizzes" -Token $script:AccessToken
        if ($result.Success -and $result.Data.success) {
            if ($result.Data.data.Count -gt 0) {
                $script:QuizId = $result.Data.data[0].id
                Write-Success "Quizzes retrieved successfully"
            }
            else {
                Write-Success "Quizzes endpoint working (no data)"
            }
        }
        else {
            Write-Failure "Failed to get quizzes" $result.Error
        }
        
        if ($script:QuizId) {
            Write-Test "Submit Quiz Answer"
            $submitBody = @{
                selectedAnswer = "Array"
                timeTaken = 30
            }
            
            $result = Test-Endpoint -Method "POST" -Endpoint "/api/v1/products/$script:ProductId/quizzes/$script:QuizId/submit" -Body $submitBody -Token $script:AccessToken
            if ($result.Success -and $result.Data.success) {
                Write-Success "Quiz answer submitted successfully"
            }
            else {
                Write-Failure "Failed to submit quiz answer" $result.Error
            }
        }
        
        Write-Test "Get PDFs for Product"
        $result = Test-Endpoint -Method "GET" -Endpoint "/api/v1/products/$script:ProductId/pdfs" -Token $script:AccessToken
        if ($result.Success -and $result.Data.success) {
            Write-Success "PDFs retrieved successfully"
        }
        else {
            Write-Failure "Failed to get PDFs" $result.Error
        }
    }
}

function Test-Bookmarks {
    Write-Header "5. BOOKMARK TESTS"
    
    if ($script:QnaId) {
        Write-Test "Add Q&A Bookmark"
        $body = @{
            qnaId = $script:QnaId
        }
        
        $result = Test-Endpoint -Method "POST" -Endpoint "/api/v1/users/bookmarks" -Body $body -Token $script:AccessToken
        if ($result.Success -and $result.Data.success) {
            $bookmarkId = $result.Data.data.id
            Write-Success "Q&A bookmarked successfully"
            
            Write-Test "Get All Bookmarks"
            $result = Test-Endpoint -Method "GET" -Endpoint "/api/v1/users/bookmarks" -Token $script:AccessToken
            if ($result.Success -and $result.Data.success) {
                Write-Success "Bookmarks retrieved successfully"
            }
            else {
                Write-Failure "Failed to get bookmarks" $result.Error
            }
            
            Write-Test "Remove Bookmark"
            $result = Test-Endpoint -Method "DELETE" -Endpoint "/api/v1/users/bookmarks/$bookmarkId" -Token $script:AccessToken
            if ($result.Success -and $result.Data.success) {
                Write-Success "Bookmark removed successfully"
            }
            else {
                Write-Failure "Failed to remove bookmark" $result.Error
            }
        }
        else {
            Write-Failure "Failed to add Q&A bookmark" $result.Error
        }
    }
}

function Test-Progress {
    Write-Header "6. PROGRESS TRACKING TESTS"
    
    if ($script:TopicId) {
        Write-Test "Update Topic Progress"
        $body = @{
            topicId = $script:TopicId
            completionPercent = 75
            score = 85.5
        }
        
        $result = Test-Endpoint -Method "POST" -Endpoint "/api/v1/users/progress" -Body $body -Token $script:AccessToken
        if ($result.Success -and $result.Data.success) {
            Write-Success "Progress updated successfully"
        }
        else {
            Write-Failure "Failed to update progress" $result.Error
        }
    }
}

function Test-AdminEndpoints {
    Write-Header "7. ADMIN ENDPOINT TESTS"
    
    Write-Test "Login as Master Admin"
    $adminLogin = @{
        email = "admin@example.com"
        password = "Admin123!"
    }
    
    $result = Test-Endpoint -Method "POST" -Endpoint "/api/v1/auth/login" -Body $adminLogin
    if ($result.Success -and $result.Data.success) {
        $adminToken = $result.Data.data.accessToken
        Write-Success "Admin login successful"
        
        Write-Test "Admin: Get Analytics"
        $result = Test-Endpoint -Method "GET" -Endpoint "/api/v1/admin/analytics" -Token $adminToken
        if ($result.Success -and $result.Data.success) {
            Write-Success "Analytics retrieved successfully"
        }
        else {
            Write-Failure "Failed to get analytics" $result.Error
        }
        
        Write-Test "Regular User Cannot Access Admin Routes (should fail)"
        $result = Test-Endpoint -Method "GET" -Endpoint "/api/v1/admin/products" -Token $script:AccessToken
        if ($result.StatusCode -eq 403) {
            Write-Success "Admin access correctly restricted"
        }
        else {
            Write-Failure "Regular user should not access admin routes"
        }
    }
    else {
        Write-Failure "Admin login failed - skipping admin tests" $result.Error
    }
}

function Test-Logout {
    Write-Header "8. LOGOUT TEST"
    
    Write-Test "User Logout"
    $body = @{
        refreshToken = $script:RefreshToken
    }
    
    $result = Test-Endpoint -Method "POST" -Endpoint "/api/v1/auth/logout" -Body $body -Token $script:AccessToken
    if ($result.Success -and $result.Data.success) {
        Write-Success "Logout successful"
    }
    else {
        Write-Failure "Logout failed" $result.Error
    }
}

# =====================================================
# Main Execution
# =====================================================

Clear-Host

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                            ║" -ForegroundColor Cyan
Write-Host "║   🧪 Multi-Product Learning API - Test Suite              ║" -ForegroundColor Cyan
Write-Host "║                                                            ║" -ForegroundColor Cyan
Write-Host "║   Testing API at: $ApiUrl" -ForegroundColor Cyan
Write-Host "║                                                            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Check if server is running
Write-Host "Checking if server is running..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$ApiUrl/health" -Method GET -UseBasicParsing -TimeoutSec 5
    Write-Host "✓ Server is running!`n" -ForegroundColor Green
}
catch {
    Write-Host "✗ ERROR: API server is not running at $ApiUrl" -ForegroundColor Red
    Write-Host "Please start the server with: npm run dev" -ForegroundColor Yellow
    exit 1
}

$startTime = Get-Date

# Run all tests
Test-ServerHealth
Test-Authentication
Test-UserEndpoints
Test-ProductEndpoints
Test-Bookmarks
Test-Progress
Test-AdminEndpoints
Test-Logout

$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

# Print Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TEST SUMMARY" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Total Tests: $script:TotalTests"
Write-Host "Passed: $script:PassedTests" -ForegroundColor Green
Write-Host "Failed: $script:FailedTests" -ForegroundColor Red
Write-Host "Duration: $([math]::Round($duration, 2))s`n"

if ($script:FailedTests -eq 0) {
    Write-Host "✓ ALL TESTS PASSED! 🎉`n" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "✗ SOME TESTS FAILED`n" -ForegroundColor Red
    exit 1
}