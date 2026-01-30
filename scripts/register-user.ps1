# Register a user on sync_server. Run this AFTER the server is running.
# Usage: .\register-user.ps1 [baseUrl]
# Example: .\register-user.ps1 http://localhost:8080

param(
    [string]$BaseUrl = "http://localhost:8080"
)

$body = @{ User = "rachevyavor@gmail.com"; Password = "3597" } | ConvertTo-Json
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/auth/register" -Method POST -ContentType "application/json" -Body $body
    Write-Host "Registered. Token: $($response.Token); UserId: $($response.UserId)"
} catch {
    Write-Host "Error: $_"
}
