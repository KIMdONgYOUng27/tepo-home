$ErrorActionPreference = 'Stop'
$nodeCommand = Get-Command node -ErrorAction SilentlyContinue
$nodePath = if ($nodeCommand) { $nodeCommand.Source } else { Join-Path $env:USERPROFILE '.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe' }
if (-not (Test-Path -LiteralPath $nodePath)) { throw 'Node.js가 필요합니다.' }
$alreadyServing = $false
try {
    $response = Invoke-WebRequest -Uri 'http://127.0.0.1:4197/' -UseBasicParsing -TimeoutSec 2
    $alreadyServing = $response.StatusCode -eq 200
} catch { }
if (-not $alreadyServing) {
    Start-Process -FilePath $nodePath -ArgumentList ('"' + (Join-Path $PSScriptRoot 'serve.mjs') + '"') -WorkingDirectory $PSScriptRoot -WindowStyle Hidden
}
Start-Process 'http://127.0.0.1:4197/'
