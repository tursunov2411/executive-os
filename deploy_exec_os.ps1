# ================================================
# EXECUTIVE OS — One-Command Full Stack Deployment (Windows)
# ================================================
# 1. Deploy FastAPI backend (Railway)
# 2. Update frontend .env.local with backend URL
# 3. Deploy Next.js frontend (Vercel)
# 4. Update iOS APIService.swift with backend URL
# 5. Optionally commit and push URL changes
# ================================================
# Prerequisites: railway CLI, vercel CLI, git
#   npm install -g railway vercel
#   railway login; vercel login
# ================================================

param(
    [switch]$SkipBackend,
    [switch]$SkipFrontend,
    [switch]$SkipIos,
    [switch]$Commit
)

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot
$BackendDir  = Join-Path $ProjectRoot "backend"
$FrontendDir = Join-Path $ProjectRoot "frontend"
$IosDir      = Join-Path $ProjectRoot "ios-companion"
$IosApiFile  = Join-Path $IosDir "APIService.swift"

# Optional env override (e.g. $env:BACKEND_URL = "https://...")
$BackendUrl = $env:BACKEND_URL
$RailwayProject = if ($env:RAILWAY_PROJECT) { $env:RAILWAY_PROJECT } else { "executive-os-backend" }
$VercelProject  = if ($env:VERCEL_PROJECT)  { $env:VERCEL_PROJECT }  else { "executive-os" }

Write-Host ""
Write-Host " =============================================" -ForegroundColor Cyan
Write-Host "  EXECUTIVE OS — DEPLOYMENT" -ForegroundColor Cyan
Write-Host " =============================================" -ForegroundColor Cyan
Write-Host ""

# --------------------------
# 1. Deploy Backend (Railway)
# --------------------------
if (-not $SkipBackend) {
    Write-Host "[1/5] Deploying FastAPI backend (Railway)..." -ForegroundColor Yellow
    Push-Location $BackendDir
    try {
        railway up --yes 2>$null; if ($LASTEXITCODE -ne 0) { railway up }
        if (-not $BackendUrl) {
            $status = railway status 2>$null
            if ($status -match 'https?://[^\s]+') { $BackendUrl = $Matches[0] }
        }
        if (-not $BackendUrl) {
            $BackendUrl = Read-Host "Enter backend URL (e.g. https://xxx.railway.app)"
        }
    } finally { Pop-Location }
    $BackendUrl = $BackendUrl.TrimEnd('/')
    Write-Host "Backend deployed at $BackendUrl" -ForegroundColor Green
} else {
    if (-not $BackendUrl -and (Test-Path (Join-Path $FrontendDir ".env.local"))) {
        $line = Get-Content (Join-Path $FrontendDir ".env.local") | Where-Object { $_ -match "NEXT_PUBLIC_BACKEND_URL" }
        if ($line) { $BackendUrl = ($line -split "=", 2)[1].Trim().Trim('"').Trim("'") }
    }
    if (-not $BackendUrl) { $BackendUrl = Read-Host "Enter backend URL" }
    Write-Host "[1/5] Backend deploy skipped (using BACKEND_URL=$BackendUrl)" -ForegroundColor Gray
}

# --------------------------
# 2. Update Frontend .env.local
# --------------------------
Write-Host ""
Write-Host "[2/5] Updating frontend .env.local..." -ForegroundColor Yellow
$envContent = "NEXT_PUBLIC_BACKEND_URL=$BackendUrl"
$envPath = Join-Path $FrontendDir ".env.local"
if (-not (Test-Path $FrontendDir)) { New-Item -ItemType Directory -Path $FrontendDir -Force | Out-Null }
Set-Content -Path $envPath -Value $envContent -Encoding UTF8
Write-Host "Frontend .env.local updated" -ForegroundColor Green

# --------------------------
# 3. Deploy Frontend (Vercel)
# --------------------------
if (-not $SkipFrontend) {
    Write-Host ""
    Write-Host "[3/5] Deploying Next.js frontend (Vercel)..." -ForegroundColor Yellow
    Push-Location $FrontendDir
    try {
        vercel --prod --yes 2>$null; if ($LASTEXITCODE -ne 0) { vercel --prod --confirm }
        Write-Host "Frontend deployed to Vercel" -ForegroundColor Green
    } finally { Pop-Location }
} else {
    Write-Host ""
    Write-Host "[3/5] Frontend deploy skipped" -ForegroundColor Gray
}

# --------------------------
# 4. Update iOS APIService.swift
# --------------------------
if (-not $SkipIos -and (Test-Path $IosApiFile)) {
    Write-Host ""
    Write-Host "[4/5] Updating iOS APIService.swift baseURL..." -ForegroundColor Yellow
    $content = Get-Content $IosApiFile -Raw
    $content = $content -replace 'baseURL = "[^"]*"', "baseURL = `"$BackendUrl`""
    Set-Content -Path $IosApiFile -Value $content -Encoding UTF8 -NoNewline:$false
    Write-Host "iOS APIService.swift updated with $BackendUrl" -ForegroundColor Green
} elseif (-not $SkipIos) {
    Write-Host ""
    Write-Host "[4/5] APIService.swift not found at $IosApiFile" -ForegroundColor DarkYellow
} else {
    Write-Host ""
    Write-Host "[4/5] iOS update skipped" -ForegroundColor Gray
}

# --------------------------
# 5. Optional: Commit and push
# --------------------------
Write-Host ""
if ($Commit) {
    Write-Host "[5/5] Committing and pushing URL updates..." -ForegroundColor Yellow
    Push-Location $ProjectRoot
    try {
        git add "$FrontendDir\.env.local", $IosApiFile 2>$null
        $status = git diff --staged --quiet 2>$null; $hasChanges = $LASTEXITCODE -ne 0
        if ($hasChanges) {
            git commit -m "chore: update frontend and iOS backend URLs for deployment"
            git push origin main
            Write-Host "Changes pushed to GitHub" -ForegroundColor Green
        } else {
            Write-Host "No changes to commit." -ForegroundColor Gray
        }
    } finally { Pop-Location }
} else {
    Write-Host "[5/5] Commit skipped (use -Commit to commit and push)" -ForegroundColor Gray
}

Write-Host ""
Write-Host " =============================================" -ForegroundColor Cyan
Write-Host "  EXECUTIVE OS DEPLOYMENT COMPLETE" -ForegroundColor Cyan
Write-Host " =============================================" -ForegroundColor Cyan
Write-Host "  Backend:  $BackendUrl"
Write-Host "  Frontend: (see Vercel dashboard or 'vercel ls')"
Write-Host " =============================================" -ForegroundColor Cyan
Write-Host ""
