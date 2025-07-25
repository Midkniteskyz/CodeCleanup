# Specify the URL of the website to visit
$url = "https://google.com"  # Replace with the URL you want to visit

# Specify the string you want to search for on the web page
$searchString = "Advanced"  # Replace with the string you want to find

# Send an HTTP GET request to the website and capture the response
$response = Invoke-WebRequest -Uri $url

# Check if the request was successful (HTTP status code 200)
if ($response.StatusCode -eq 200) {
    # Check if the response content contains the search string
    if ($response.Content -like "*$searchString*") {
        Write-Host "Search string '$searchString' found on the web page."
    } else {
        Write-Host "Search string '$searchString' not found on the web page."
    }
} else {
    Write-Host "HTTP request to $url failed with status code $($response.StatusCode)."
}
