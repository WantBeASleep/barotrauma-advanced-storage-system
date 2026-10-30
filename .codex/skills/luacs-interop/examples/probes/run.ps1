<#
.SYNOPSIS
Проверяет примеры на workshop DLL без запуска игры и изменения модов.
.DESCRIPTION
Требуется PowerShell 7.6 (Roslyn Add-Type). Каждый запуск — новый процесс pwsh.
Используется настоящий LuaUserDataService; поиск сборок заменён TypeLookupProxy.
Загрузчик пакетов, GUI, сеть и жизненный цикл игры здесь не запускаются.
.PARAMETER BinaryRoot
Каталог Binary установленного LuaCsForBarotrauma.
.EXAMPLE
pwsh -NoProfile -File ./run.ps1 -BinaryRoot 'D:/SteamLibrary/steamapps/workshop/content/602960/2559634234/Binary'
#>
param([Parameter(Mandatory = $true)][string]$BinaryRoot)
$ErrorActionPreference = 'Stop'
$binaryDirectory = (Resolve-Path -LiteralPath $BinaryRoot).Path
$demoRoot = Join-Path $PSScriptRoot '../bridge-demo'
$references = @(
    (Join-Path $binaryDirectory 'MoonSharp.Interpreter.dll'),
    (Join-Path $binaryDirectory 'BarotraumaCore.dll'),
    (Join-Path $binaryDirectory 'Barotrauma.dll'),
    (Join-Path $binaryDirectory 'FluentResults.dll')
)
foreach ($reference in $references) { Add-Type -Path $reference }
$frameworkReferences = @(Get-ChildItem (Join-Path $PSHOME 'ref') -Filter '*.dll' | Select-Object -ExpandProperty FullName)
$sources = @(
    (Join-Path $demoRoot 'CSharp/Contracts.cs'),
    (Join-Path $demoRoot 'CSharp/Plugin.cs'),
    (Join-Path $PSScriptRoot 'ProbeTypes.cs'),
    (Join-Path $PSScriptRoot 'Host.cs')
)
# The isolated host uses .NET 10; the game assemblies target .NET 8.
Add-Type -Path $sources -ReferencedAssemblies ($references + $frameworkReferences) -CompilerOptions '/nowarn:1701'
[BridgeProbes.Host]::Run((Join-Path $demoRoot 'Lua/Autorun/main.lua'), (Join-Path $PSScriptRoot 'probes.lua'))
