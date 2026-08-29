#requires -Version 5.1
# Cursor 界面汉化（不依赖 Python）
param(
    [ValidateSet("apply", "revert", "status")]
    [string]$Cmd = "apply"
)

$ErrorActionPreference = "Stop"
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$DictSrc = Join-Path $Here "cursor-zh.js"
$Tag = '<script src="./cursor-zh.js"></script>'
$WbTag = '<script src="./workbench.js" type="module"></script>'
$Backup = Join-Path $env:APPDATA "CursorZh\backup"
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Get-CursorApp {
    $cands = @()
    if ($env:CURSOR_PATH) {
        $p = $env:CURSOR_PATH
        if ((Test-Path $p -PathType Leaf) -and ([IO.Path]::GetFileName($p) -ieq "Cursor.exe")) {
            $p = Join-Path (Split-Path $p -Parent) "resources\app"
        }
        $cands += $p
        $cands += (Join-Path $p "resources\app")
    }
    $cands += @(
        (Join-Path $env:LOCALAPPDATA "Programs\cursor\resources\app"),
        "C:\Program Files\Cursor\resources\app",
        "C:\Program Files (x86)\Cursor\resources\app"
    )
    foreach ($c in $cands) {
        $html = Join-Path $c "out\vs\code\electron-sandbox\workbench\workbench.html"
        if (Test-Path $html) { return (Resolve-Path $c).Path }
    }
    throw "找不到 Cursor 安装目录。可设置 CURSOR_PATH"
}

function Get-HtmlChecksum([string]$Path) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $hash = $sha.ComputeHash($bytes)
    $b64 = [Convert]::ToBase64String($hash)
    return $b64.TrimEnd("=")
}

function Test-CursorRunning {
    return [bool](Get-Process -Name "Cursor" -ErrorAction SilentlyContinue)
}

function Stop-CursorSafe {
    Get-Process -Name "Cursor" -ErrorAction SilentlyContinue | Stop-Process -Force
    $n = 0
    while (Test-CursorRunning -and $n -lt 40) {
        Start-Sleep -Milliseconds 250
        $n++
    }
    if (Test-CursorRunning) { throw "Cursor 仍在运行，请先手动退出。" }
}

function Start-CursorApp([string]$App) {
    $exe = Join-Path (Split-Path (Split-Path $App -Parent) -Parent) "Cursor.exe"
    if (Test-Path $exe) { Start-Process $exe }
}

function Update-HtmlChecksum([string]$App) {
    $prod = Join-Path $App "product.json"
    $html = Join-Path $App "out\vs\code\electron-sandbox\workbench\workbench.html"
    $sum = Get-HtmlChecksum $html
    $text = [System.IO.File]::ReadAllText($prod)
    $pat = '"vs/code/electron-sandbox/workbench/workbench.html":\s*"[^"]+"'
    $repl = '"vs/code/electron-sandbox/workbench/workbench.html": "' + $sum + '"'
    $new = [regex]::Replace($text, $pat, $repl, 1)
    if ($new -eq $text) {
        Write-Warning "product.json 中没有 workbench.html checksum，已跳过。"
        return
    }
    [System.IO.File]::WriteAllText($prod, $new, $Utf8NoBom)
}

function Write-Locale {
    $user = Join-Path $env:APPDATA "Cursor\User"
    New-Item -ItemType Directory -Force -Path $user | Out-Null
    $payload = "{`n`t`"locale`": `"zh-cn`"`n}`n"
    [System.IO.File]::WriteAllText((Join-Path $user "locale.json"), $payload, $Utf8NoBom)
}

function Remove-ZhTag([string]$Text) {
    $clean = $Text.Replace("`r`n`t$Tag", "")
    $clean = $clean.Replace("`n`t$Tag", "")
    $clean = $clean.Replace("`r`n$Tag", "")
    $clean = $clean.Replace("`n$Tag", "")
    return $clean.Replace($Tag, "")
}

function Get-TextHash([string]$Text) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    return ([BitConverter]::ToString($sha.ComputeHash($Utf8NoBom.GetBytes($Text)))).Replace("-", "").ToLowerInvariant()
}

function Backup-CursorFiles([string]$App, [string]$Html, [string]$Product) {
    $version = "unknown"
    $package = Join-Path $App "package.json"
    try { $version = (Get-Content -Raw $package | ConvertFrom-Json).version } catch {}
    if (-not $version) { $version = "unknown" }
    $appId = (Get-TextHash ([IO.Path]::GetFullPath($App).ToLowerInvariant())).Substring(0, 12)
    $baseline = Remove-ZhTag $Html
    $htmlId = (Get-TextHash $baseline).Substring(0, 16)
    $dir = Join-Path $Backup (Join-Path $appId (Join-Path $version $htmlId))
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $htmlBak = Join-Path $dir "workbench.html.orig"
    $prodBak = Join-Path $dir "product.json.orig"
    if (-not (Test-Path $htmlBak)) {
        [System.IO.File]::WriteAllText($htmlBak, $baseline, $Utf8NoBom)
    }
    if (-not (Test-Path $prodBak)) {
        [System.IO.File]::WriteAllText($prodBak, $Product, $Utf8NoBom)
    }
    $manifest = @{
        installerVersion = "1.0.0"
        cursorVersion = $version
        appPath = [IO.Path]::GetFullPath($App)
        workbenchSha256 = Get-TextHash $baseline
        createdAt = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
    } | ConvertTo-Json
    [System.IO.File]::WriteAllText((Join-Path $dir "manifest.json"), $manifest + "`n", $Utf8NoBom)
    return $dir
}

$App = Get-CursorApp
$Html = Join-Path $App "out\vs\code\electron-sandbox\workbench\workbench.html"
$Dst = Join-Path $App "out\vs\code\electron-sandbox\workbench\cursor-zh.js"

if ($Cmd -eq "status") {
    Write-Host "Cursor app: $App"
    Write-Host "词典: $(Test-Path $Dst)"
    Write-Host "注入: $((Get-Content -Raw $Html).Contains($Tag))"
    Write-Host "备份: $Backup"
    exit 0
}

if (Test-CursorRunning) { Stop-CursorSafe }

if ($Cmd -eq "apply") {
    if (-not (Test-Path $DictSrc)) { throw "缺少 cursor-zh.js" }
    $prod = Join-Path $App "product.json"
    $htmlBytes = [System.IO.File]::ReadAllBytes($Html)
    $prodBytes = [System.IO.File]::ReadAllBytes($prod)
    $dictBytes = if (Test-Path $Dst) { [System.IO.File]::ReadAllBytes($Dst) } else { $null }
    $raw = [System.IO.File]::ReadAllText($Html)
    $productRaw = [System.IO.File]::ReadAllText($prod)
    $backupDir = Backup-CursorFiles $App $raw $productRaw
    Write-Host "已备份原文件: $backupDir"
    try {
        Copy-Item $DictSrc $Dst -Force
        if (-not $raw.Contains($Tag)) {
            if (-not $raw.Contains($WbTag)) { throw "workbench.html 找不到 workbench.js 标签" }
            $nl = if ($raw.Contains("`r`n")) { "`r`n" } else { "`n" }
            $raw = $raw.Replace($WbTag, "$WbTag$nl`t$Tag")
            [System.IO.File]::WriteAllText($Html, $raw, $Utf8NoBom)
        }
        Update-HtmlChecksum $App
        Write-Locale
    } catch {
        [System.IO.File]::WriteAllBytes($Html, $htmlBytes)
        [System.IO.File]::WriteAllBytes($prod, $prodBytes)
        if ($null -eq $dictBytes) {
            if (Test-Path $Dst) { Remove-Item $Dst -Force }
        } else {
            [System.IO.File]::WriteAllBytes($Dst, $dictBytes)
        }
        throw
    }
    Write-Host "汉化完成。请完全重启 Cursor。"
} elseif ($Cmd -eq "revert") {
    $raw = [System.IO.File]::ReadAllText($Html)
    $clean = Remove-ZhTag $raw
    if ($clean -ne $raw) {
        [System.IO.File]::WriteAllText($Html, $clean, $Utf8NoBom)
        Update-HtmlChecksum $App
    }
    if (Test-Path $Dst) { Remove-Item $Dst -Force }
    Write-Host "已取消专用界面汉化。"
}

Start-CursorApp $App
