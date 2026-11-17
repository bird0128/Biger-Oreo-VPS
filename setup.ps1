
# ==========================================
# Biger-Oreo VPS - Windows Environment Setup
# ==========================================

$ErrorActionPreference = "Stop"

$RepoUrl = "https://github.com/bird0128/Biger-Oreo-VPS.git"
$ProjectDir = Join-Path $env:USERPROFILE "Biger-Oreo-VPS"

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "       Biger-Oreo VPS Setup" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# 1. Request administrator privileges
$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)
$IsAdmin = $Principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $IsAdmin) {
    Write-Host "正在申请管理员权限..." -ForegroundColor Yellow

    $ScriptPath = $PSCommandPath

    Start-Process powershell.exe `
        -Verb RunAs `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""

    exit
}

# 2. Check and install Git
Write-Host "[1/5] 检查 Git..." -ForegroundColor Cyan

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "未检测到 Git，正在尝试通过 WinGet 安装..." -ForegroundColor Yellow

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "未检测到 WinGet。请先安装 Windows 应用安装程序后重试。"
    }

    winget install --id Git.Git -e --source winget `
        --accept-package-agreements `
        --accept-source-agreements

    if ($LASTEXITCODE -ne 0) {
        throw "Git 自动安装失败。"
    }

    $GitCandidates = @(
    "$env:ProgramFiles\Git\cmd\git.exe",
    "${env:ProgramFiles(x86)}\Git\cmd\git.exe",
    "$env:LOCALAPPDATA\Programs\Git\cmd\git.exe"
)

$GitExe = $GitCandidates |
    Where-Object { Test-Path $_ } |
    Select-Object -First 1

if (-not $GitExe) {
    throw "Git 安装程序已执行，但没有找到 Git。"
}

$GitBin = Split-Path $GitExe -Parent
$env:Path = "$GitBin;$env:Path"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git 安装后仍无法识别。"
}
}

Write-Host "Git 检查通过。" -ForegroundColor Green

# 3. Check and install OpenSSH Client
Write-Host ""
Write-Host "[2/5] 检查 OpenSSH Client..." -ForegroundColor Cyan


# 3. Check and install OpenSSH Client
Write-Host ""
Write-Host "[2/5] 检查 OpenSSH Client..." -ForegroundColor Cyan

$SshPath = "$env:WINDIR\System32\OpenSSH\ssh.exe"

if (-not (Test-Path $SshPath)) {
    Write-Host "未检测到 SSH，正在安装 OpenSSH Client..." -ForegroundColor Yellow

    $Capability = Get-WindowsCapability -Online |
        Where-Object Name -Like "OpenSSH.Client*" |
        Select-Object -First 1

    if (-not $Capability) {
        throw "无法查询 Windows OpenSSH 功能。"
    }

    if ($Capability.State -ne "Installed") {
        Add-WindowsCapability -Online -Name $Capability.Name -ErrorAction Stop | Out-Null
    }

    $Capability = Get-WindowsCapability -Online -Name $Capability.Name

    if ($Capability.State -ne "Installed") {
        throw "OpenSSH Client 安装未成功。"
    }
}

if (-not (Test-Path $SshPath)) {
    throw "OpenSSH Client 文件不存在：$SshPath"
}

$SshDirectory = Split-Path $SshPath -Parent
$env:Path = "$SshDirectory;$env:Path"

Write-Host "OpenSSH Client 检查通过。" -ForegroundColor Green

# 4. Clone or update project
Write-Host ""
Write-Host "[3/5] 检查项目文件..." -ForegroundColor Cyan

if (Test-Path (Join-Path $ProjectDir ".git")) {
    Write-Host "检测到已有项目，检查 Git 状态..."

    Push-Location $ProjectDir

    try {
	$CurrentBranch = git branch --show-current

if ($LASTEXITCODE -ne 0 -or $CurrentBranch -ne "main") {
    throw "当前项目不在 main 分支，已停止更新。"
}
        $RemoteUrl = git remote get-url origin

        if ($LASTEXITCODE -ne 0 -or $RemoteUrl -ne $RepoUrl) {
            throw "当前目录的 Git 仓库地址与目标项目不一致，已停止。"
        }

        $GitStatus = git status --porcelain

        if ($LASTEXITCODE -ne 0) {
            throw "无法检查 Git 仓库状态。"
        }

        if ($GitStatus) {
            throw "项目存在未提交的本地修改。为避免覆盖，已停止更新。"
        }

        git pull --ff-only origin main

        if ($LASTEXITCODE -ne 0) {
            throw "项目更新失败。"
        }
    }
    finally {
        Pop-Location
    }
}
elseif (Test-Path $ProjectDir) {
    throw "目标目录已存在，但不是有效的 Git 仓库：$ProjectDir"
}
else {
    git clone $RepoUrl $ProjectDir

    if ($LASTEXITCODE -ne 0) {
        throw "GitHub 项目下载失败。"
    }
}

# 5. Verify and launch deployment
Write-Host ""
Write-Host "[4/5] 检查部署文件..." -ForegroundColor Cyan

$DeployScript = Join-Path $ProjectDir "deploy.ps1"

if (-not (Test-Path $DeployScript)) {
    throw "没有找到 deploy.ps1。"
}

Write-Host "部署文件检查通过。" -ForegroundColor Green

Write-Host ""
Write-Host "[5/5] 启动 VPS 自动部署..." -ForegroundColor Cyan
Write-Host ""

Set-Location $ProjectDir

& powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& { `$ErrorActionPreference = 'Stop'; try { & '$DeployScript'; if (`$LASTEXITCODE -ne 0) { exit `$LASTEXITCODE }; exit 0 } catch { Write-Error `$_; exit 1 } }"

if ($LASTEXITCODE -ne 0) {
    throw "VPS 部署脚本执行失败。"
}

Write-Host ""
Write-Host "Biger-Oreo VPS 部署流程结束。" -ForegroundColor Green
