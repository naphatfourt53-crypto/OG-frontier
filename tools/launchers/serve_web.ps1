# ---------------------------------------------------------------------------
#  LAST LAUNCH - tiny static web server (PowerShell 5.1 compatible).
#  The Web export cannot run from file://, so PLAY_WEB.bat starts this server.
#  Loopback only, one request per connection, no directory listing.
# ---------------------------------------------------------------------------
$ErrorActionPreference = "Stop"

$root = (Split-Path -Parent $MyInvocation.MyCommand.Path).TrimEnd('\')
$port = 8000
$listener = $null

for ($p = 8000; $p -le 8010; $p++) {
    try {
        $candidate = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, [int]$p)
        $candidate.Start()
        $listener = $candidate
        $port = $p
        break
    } catch {
        $listener = $null
    }
}

if ($null -eq $listener) {
    Write-Host "[X] Could not open a local port (8000-8010)."
    Write-Host "    Close other local servers and try again."
    Read-Host "Press Enter to close"
    exit 1
}

$types = @{
    ".html" = "text/html; charset=utf-8"
    ".htm"  = "text/html; charset=utf-8"
    ".js"   = "text/javascript; charset=utf-8"
    ".wasm" = "application/wasm"
    ".pck"  = "application/octet-stream"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
    ".json" = "application/json; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".txt"  = "text/plain; charset=utf-8"
}

$url = "http://localhost:$port/index.html"
Write-Host ""
Write-Host "  LAST LAUNCH - Web build"
Write-Host "  Serving: $root"
Write-Host "  Open:    $url"
Write-Host "  Keep this window open while playing. Press Ctrl+C to stop."
Write-Host ""
Start-Process $url

while ($true) {
    $client = $listener.AcceptTcpClient()
    try {
        $client.ReceiveTimeout = 5000
        $client.SendTimeout = 30000
        $stream = $client.GetStream()
        $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::ASCII, $false, 1024, $true)
        $requestLine = $reader.ReadLine()
        if ([string]::IsNullOrEmpty($requestLine)) {
            continue
        }
        while ($true) {
            $header = $reader.ReadLine()
            if ($null -eq $header -or $header -eq "") {
                break
            }
        }

        $parts = $requestLine.Split(" ")
        $method = $parts[0]
        $rawPath = ""
        if ($parts.Length -ge 2) {
            $rawPath = $parts[1]
        }
        $path = [System.Uri]::UnescapeDataString(($rawPath -split '\?')[0]).TrimStart('/')
        if ([string]::IsNullOrWhiteSpace($path)) {
            $path = "index.html"
        }

        $status = "200 OK"
        $body = $null
        $contentType = "application/octet-stream"

        if ($path -match '\.\.' -or $path.StartsWith("/")) {
            $status = "403 Forbidden"
            $body = [System.Text.Encoding]::UTF8.GetBytes("Forbidden")
            $contentType = "text/plain; charset=utf-8"
        } else {
            $full = Join-Path $root ($path -replace '/', [System.IO.Path]::DirectorySeparatorChar)
            if (Test-Path -LiteralPath $full -PathType Leaf) {
                $body = [System.IO.File]::ReadAllBytes($full)
                $ext = [System.IO.Path]::GetExtension($full).ToLower()
                if ($types.ContainsKey($ext)) {
                    $contentType = $types[$ext]
                }
            } else {
                $status = "404 Not Found"
                $body = [System.Text.Encoding]::UTF8.GetBytes("Not found")
                $contentType = "text/plain; charset=utf-8"
            }
        }

        $head = "HTTP/1.1 $status`r`nContent-Type: $contentType`r`nContent-Length: $($body.Length)`r`nCache-Control: no-store`r`nConnection: close`r`n`r`n"
        $headBytes = [System.Text.Encoding]::ASCII.GetBytes($head)
        $stream.Write($headBytes, 0, $headBytes.Length)
        if ($method -ne "HEAD" -and $body.Length -gt 0) {
            $stream.Write($body, 0, $body.Length)
        }
        $stream.Flush()
    } catch {
        # A browser may cancel a request; keep serving.
    } finally {
        $client.Close()
    }
}
