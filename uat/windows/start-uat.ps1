# UDL Assets RV030 - isolated Windows one-click static preview.
# Only serves the compiled files shipped in the current UAT package.
# Does NOT connect to any production data or deploy a server.
param([int]$Port = 8765, [switch]$NoBrowser)

$ErrorActionPreference = 'Stop'
$root = Join-Path $PSScriptRoot 'web'
if (-not (Test-Path (Join-Path $root 'index.html'))) {
  throw 'Folder web/index.html tidak ditemukan. Ekstrak SELURUH paket UAT Windows dari GitHub Actions.'
}
$root = [System.IO.Path]::GetFullPath($root)
if (-not $root.EndsWith([System.IO.Path]::DirectorySeparatorChar.ToString())) {
  $root += [System.IO.Path]::DirectorySeparatorChar
}

$address = "http://127.0.0.1:$Port/"
$server = [System.Net.HttpListener]::new()
$server.Prefixes.Add($address)
try {
  $server.Start()
} catch {
  throw "Server lokal gagal dibuka pada $address. Pastikan port $Port tidak dipakai proses lain. Rincian: $($_.Exception.Message)"
}
Write-Host "UDL Assets RV030 tersedia di $address"
Write-Host 'Data UAT disimpan di profil browser khusus; bukan profil browser operasional.'
Write-Host 'Tekan Ctrl+C untuk menghentikan server lokal.'

if (-not $NoBrowser) {
  $dataDir = Join-Path $env:LOCALAPPDATA 'UDLAssets\RV030-UAT\BrowserProfile'
  New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
  $browsers = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
  )
  $browser = $browsers | Where-Object { Test-Path $_ } | Select-Object -First 1
  if ($browser) {
    Start-Process -FilePath $browser -ArgumentList @(
      "--user-data-dir=`"$dataDir`"",
      '--no-first-run', '--new-window', $address
    )
  } else {
    Write-Warning 'Chrome/Edge tidak ditemukan di lokasi umum; membuka browser default.'
    Start-Process $address
  }
}

$mime = @{
  '.html'='text/html; charset=utf-8'
  '.js'='application/javascript; charset=utf-8'
  '.mjs'='application/javascript; charset=utf-8'
  '.css'='text/css; charset=utf-8'
  '.json'='application/json; charset=utf-8'
  '.wasm'='application/wasm'
  '.png'='image/png'
  '.jpg'='image/jpeg'
  '.jpeg'='image/jpeg'
  '.webp'='image/webp'
  '.svg'='image/svg+xml'
  '.ico'='image/x-icon'
  '.woff'='font/woff'
  '.woff2'='font/woff2'
  '.ttf'='font/ttf'
  '.otf'='font/otf'
  '.bin'='application/octet-stream'
  '.map'='application/json; charset=utf-8'
}

try {
  while ($server.IsListening) {
    $ctx = $server.GetContext()
    try {
      $requestPath = [System.Uri]::UnescapeDataString(
        $ctx.Request.Url.AbsolutePath).TrimStart('/')
      if ([string]::IsNullOrEmpty($requestPath)) {
        $requestPath = 'index.html'
      }
      $relative = $requestPath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
      $full = [System.IO.Path]::GetFullPath((Join-Path $root $relative))
      if (-not $full.StartsWith($root,
          [System.StringComparison]::OrdinalIgnoreCase)) {
        $ctx.Response.StatusCode = 403
        $ctx.Response.Close()
        continue
      }
      if (-not [System.IO.File]::Exists($full)) {
        if ([string]::IsNullOrEmpty([System.IO.Path]::GetExtension($full))) {
          $full = Join-Path $root 'index.html'
        } else {
          $ctx.Response.StatusCode = 404
          $ctx.Response.Close()
          continue
        }
      }
      $extension = [System.IO.Path]::GetExtension($full).ToLowerInvariant()
      $ctx.Response.ContentType = if ($mime.ContainsKey($extension)) {
        $mime[$extension]
      } else {
        'application/octet-stream'
      }
      $ctx.Response.Headers['Cache-Control'] = 'no-store'
      $bytes = [System.IO.File]::ReadAllBytes($full)
      $ctx.Response.ContentLength64 = $bytes.Length
      $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
      $ctx.Response.Close()
    } catch {
      try {
        if ($ctx.Response.OutputStream.CanWrite) {
          $ctx.Response.StatusCode = 500
          $ctx.Response.Close()
        }
      } catch {}
      Write-Warning $_.Exception.Message
    }
  }
} finally {
  $server.Stop()
  $server.Close()
}
