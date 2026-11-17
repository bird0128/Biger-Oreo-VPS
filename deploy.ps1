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

[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)

Write-Host "`n正在连接 $Remote ..." -ForegroundColor Cyan

$RemoteOutput = ssh -p $Port $Remote "curl -fL '$GitHubUrl' -o /tmp/xray-install.sh && chmod 700 /tmp/xray-install.sh && echo 'GitHub 脚本下载成功' && echo '正在检查 Bash 语法...' && bash -n /tmp/xray-install.sh && echo '语法检查通过，开始自动安装...' && XRAY_SSH_PORT=$Port XRAY_AUTO=1 bash /tmp/xray-install.sh"
$SshExitCode = $LASTEXITCODE

$RemoteOutput | ForEach-Object { Write-Host $_ }

if ($SshExitCode -ne 0) {
    Write-Host "`n自动部署失败，SSH 或远程安装脚本返回错误。" -ForegroundColor Red
    exit 1
}

$UriLine = $RemoteOutput | Where-Object { $_ -match '^BIGGER_OREO_URI=' } | Select-Object -Last 1

if (-not $UriLine) {
    Write-Host "`n错误：没有从服务器获取到节点 URI。" -ForegroundColor Red
    exit 1
}

$Uri = ($UriLine -replace '^BIGGER_OREO_URI=', '').Trim()

$UriMatch = [regex]::Match($Uri, '^vless://([^@]+)@([^:]+):(\d+)\?([^#]+)')

if (-not $UriMatch.Success) {
    Write-Host "`n错误：节点 URI 格式无法识别。" -ForegroundColor Red
    exit 1
}

$UUID = $UriMatch.Groups[1].Value
$NodeServer = $UriMatch.Groups[2].Value
$NodePort = [int]$UriMatch.Groups[3].Value
$QueryString = $UriMatch.Groups[4].Value

$Query = @{}

foreach ($Item in $QueryString.Split('&')) {
    $Pair = $Item.Split('=', 2)
    if ($Pair.Count -eq 2) {
        $Key = [uri]::UnescapeDataString($Pair[0])
        $Value = [uri]::UnescapeDataString($Pair[1])
        $Query[$Key] = $Value
    }
}

$PublicKey = $Query['pbk']
$ShortId = $Query['sid']
$SNI = $Query['sni']
$Fingerprint = $Query['fp']
$Flow = $Query['flow']

if (-not $PublicKey -or -not $ShortId -or -not $SNI) {
    Write-Host "`n错误：节点 URI 缺少 REALITY 必要参数。" -ForegroundColor Red
    exit 1
}

try {
    $GeoInfo = Invoke-RestMethod "https://ipwho.is/$NodeServer" -TimeoutSec 10 -ErrorAction Stop
    $CountryCode = $GeoInfo.country_code
}
catch {
    $CountryCode = "UNKNOWN"
}

if (-not $CountryCode) {
    $CountryCode = "UNKNOWN"
}

$NodeName = "$CountryCode-$NodeServer"

$ConfigPath = Join-Path $PSScriptRoot "biger-oreo.yaml"

$Yaml = @"
proxies:
  - name: "$NodeName"
    type: vless
    server: "$NodeServer"
    port: $NodePort
    uuid: "$UUID"
    network: tcp
    tls: true
    udp: true
    flow: "$Flow"
    servername: "$SNI"
    client-fingerprint: "$Fingerprint"
    reality-opts:
      public-key: "$PublicKey"
      short-id: "$ShortId"
      support-x25519mlkem768: true

proxy-groups:
  - name: "PROXY"
    type: select
    proxies:
      - "$NodeName"
      - DIRECT

rules:
  - MATCH,PROXY
"@

$Yaml | Set-Content -Path $ConfigPath -Encoding UTF8


$QrPath = Join-Path $PSScriptRoot "biger-oreo-qr.png"
$RemoteQrPath = "/etc/xray/vless-$UUID.png"

Write-Host "`n正在下载节点二维码..." -ForegroundColor Cyan

scp -P $Port "${Remote}:$RemoteQrPath" $QrPath

if ($LASTEXITCODE -eq 0) {
    Write-Host "二维码下载成功：$QrPath" -ForegroundColor Green
    Start-Process $QrPath
}
else {
    Write-Host "二维码下载失败，请检查 SSH/SCP 连接。" -ForegroundColor Red
}

Write-Host "`nClash 配置已生成：$ConfigPath" -ForegroundColor Green

Write-Host "`n已成功获取节点 URI。" -ForegroundColor Green

Write-Host "`n自动部署流程执行完成。" -ForegroundColor Green
