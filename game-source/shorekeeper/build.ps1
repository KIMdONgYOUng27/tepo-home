$ErrorActionPreference = 'Stop'
$engine = if ($env:GODOT_BIN) { $env:GODOT_BIN } else { Join-Path $PSScriptRoot '../tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' }
if (-not (Test-Path -LiteralPath $engine)) { throw 'tools/godot-4.7.2 폴더의 Godot 실행 파일이 필요합니다.' }
$previousAppData = $env:APPDATA
try {
    if (-not $env:GODOT_BIN) {
        $env:APPDATA = Join-Path $PSScriptRoot '../tools/godot-4.7.2/runtime-data'
        New-Item -ItemType Directory -Path $env:APPDATA -Force | Out-Null
    }
    & $engine --headless --path $PSScriptRoot --editor --import --quit
    if ($LASTEXITCODE -ne 0) { throw 'Godot import failed' }
    $modeOutput = & $engine --headless --path $PSScriptRoot --script res://tests/mode20_checks.gd 2>&1
    $modeOutput | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0 -or -not ($modeOutput -match 'MODE20: 0 errors') -or ($modeOutput -match 'SCRIPT ERROR')) { throw 'Twenty minute mode verification failed' }
    $musicOutput = & $engine --headless --path $PSScriptRoot --script res://tests/music_checks.gd 2>&1
    $musicOutput | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0 -or -not ($musicOutput -match 'MUSIC: 0 errors') -or ($musicOutput -match 'SCRIPT ERROR')) { throw 'Music verification failed' }
    $treasureOutput = & $engine --headless --path $PSScriptRoot --script res://tests/treasure_checks.gd 2>&1
    $treasureOutput | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0 -or -not ($treasureOutput -match 'TREASURE: 0 errors') -or ($treasureOutput -match 'SCRIPT ERROR')) { throw 'Treasure verification failed' }
    $fxOutput = & $engine --headless --path $PSScriptRoot --script res://tests/combat_fx_checks.gd 2>&1
    $fxOutput | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0 -or -not ($fxOutput -match 'COMBAT FX: 0 errors') -or ($fxOutput -match 'SCRIPT ERROR')) { throw 'Combat effects verification failed' }
    $presentationOutput = & $engine --headless --path $PSScriptRoot --script res://tests/presentation_checks.gd 2>&1
    $presentationOutput | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0 -or -not ($presentationOutput -match 'PRESENTATION: 0 errors') -or ($presentationOutput -match 'SCRIPT ERROR')) { throw 'Presentation verification failed' }
    $checkOutput = & $engine --headless --path $PSScriptRoot --script res://tests/full_stage.gd 2>&1
    $checkOutput | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0 -or -not ($checkOutput -match 'FULL STAGE: 0 errors') -or ($checkOutput -match 'SCRIPT ERROR')) { throw 'Game verification failed' }
    & $engine --headless --path $PSScriptRoot --export-release Web
    if ($LASTEXITCODE -ne 0) { throw 'Web export failed' }
    Move-Item -LiteralPath (Join-Path $PSScriptRoot 'web/index.pck') -Destination (Join-Path $PSScriptRoot 'web/index-v0.14.1.pck') -Force
    New-Item -ItemType Directory -Path (Join-Path $PSScriptRoot 'web/loading') -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'loading/tepo.png') -Destination (Join-Path $PSScriptRoot 'web/loading/tepo.png')
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'web-ranking.js') -Destination (Join-Path $PSScriptRoot 'web/web-ranking.js')
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'web-music.js') -Destination (Join-Path $PSScriptRoot 'web/web-music.js')
    New-Item -ItemType Directory -Path (Join-Path $PSScriptRoot 'web/music') -Force | Out-Null
    Copy-Item -Path (Join-Path $PSScriptRoot 'assets/music/*.ogg') -Destination (Join-Path $PSScriptRoot 'web/music')
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'assets/FONT-LICENSE.txt') -Destination (Join-Path $PSScriptRoot 'web/FONT-LICENSE.txt')
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'assets/HAND-FONT-LICENSE.txt') -Destination (Join-Path $PSScriptRoot 'web/HAND-FONT-LICENSE.txt')
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'assets/GODOT-LICENSE.txt') -Destination (Join-Path $PSScriptRoot 'web/GODOT-LICENSE.txt')
    Write-Host '완료: web/index.html / node serve.mjs'
} finally { $env:APPDATA = $previousAppData }
