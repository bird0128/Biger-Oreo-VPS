$ErrorActionPreference = "Stop"

$Server = Read-Host "请输入 VPS 公网 IP"
$PortInput = Read-Host "请输入 SSH 端口（默认 22）"

if ([string]::IsNullOrWhiteSpace($Server)) {
    Write-Host "错误：VPS IP 不能为空" -ForegroundColor Red
    exit 1
}

$Port = 22
if (-not [string]::IsNullOrWhiteSpace($PortInput)) {
    if (-not [int]::TryParse($PortInput, [ref]$Port) -or $Port -lt 1 -or $Port -gt 65535) {
        Write-Host "错误：SSH 端口无效" -ForegroundColor Red
        exit 1
    }
}

if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
    Write-Host "错误：未检测到 OpenSSH 客户端" -ForegroundColor Red
    exit 1
}

$Remote = "root@$Server"
$GitHubUrl = "https://raw.githubusercontent.com/bird0128/Biger-Oreo-VPS/main/xray-install.sh"

Write-Host "`n正在连接 $Remote ..." -ForegroundColor Cyan

ssh -p $Port $Remote "curl -fL '$GitHubUrl' -o /tmp/xray-install.sh && chmod 700 /tmp/xray-install.sh && echo 'GitHub 脚本下载成功' && echo '正在检查 Bash 语法...' && bash -n /tmp/xray-install.sh && echo '语法检查通过，开始自动安装...' && XRAY_AUTO=1 bash /tmp/xray-install.sh"

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n自动部署失败，SSH 或远程安装脚本返回错误。" -ForegroundColor Red
    exit 1
}

Write-Host "`n自动部署流程执行完成。" -ForegroundColor Green