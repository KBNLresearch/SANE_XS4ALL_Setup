# This script is copied from https://gitlab.com/rsc-surf-nl/plugins/ollama-windows/-/blob/main/ollama-windows.ps1
# Despite not being licensed at the time, permission was given by the author of the script to use it in this project.

# ollama-windows.ps1
# Run as Administrator
#
# Expected env vars, set by Ansible at machine level:
#   OLLAMA_VERSION=0.12.10
#   OLLAMA_MODELS_TO_PULL=qwen2.5-coder:7b,llama3.2:3b
#
# Optional:
#   OLLAMA_GITHUB_BASE_URL=https://github.com/ollama/ollama/releases/download
#   OLLAMA_INSTALL_DIR=C:\Program Files\Ollama
#   OLLAMA_MODEL_STORE=C:\ProgramData\Ollama\models

$ErrorActionPreference = "Stop"

$LogFile = "C:\logs\install-ollama.log"

function Write-Log {
    param([string]$Message)

    $dir = Split-Path $LogFile -Parent
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $line = "{0:u}: {1}" -f (Get-Date), $Message
    $line | Tee-Object -FilePath $LogFile -Append
}

function Assert-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)

    if (!$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "Run this script as Administrator."
    }
}

function Get-EnvVar {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Default = $null
    )

    $value = [Environment]::GetEnvironmentVariable($Name, "Machine")

    if ([string]::IsNullOrWhiteSpace($value)) {
        $value = [Environment]::GetEnvironmentVariable($Name, "Process")
    }

    if ([string]::IsNullOrWhiteSpace($value)) {
        return $Default
    }

    return $value
}

function Get-EnvVarOrFail {
    param([Parameter(Mandatory = $true)][string]$Name)

    $value = Get-EnvVar -Name $Name

    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "Required environment variable '$Name' is not set or empty."
    }

    return $value
}

function ConvertTo-ModelList {
    param([Parameter(Mandatory = $true)][string]$RawValue)

    return $RawValue `
        -split "[,;`n`r]+" `
        | ForEach-Object { $_.Trim() } `
        | Where-Object { $_ } `
        | Select-Object -Unique
}

function New-PublicDesktopShortcut {
    param([Parameter(Mandatory = $true)][string]$TargetPath)

    $ShortcutPath = "C:\Users\Public\Desktop\Ollama.lnk"

    $Shell = New-Object -ComObject WScript.Shell
    $Shortcut = $Shell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $TargetPath
    $Shortcut.WorkingDirectory = Split-Path $TargetPath -Parent
    $Shortcut.Save()

    Write-Log "Public desktop shortcut created: $ShortcutPath"
}

try {
    Assert-Admin

    Write-Log "Starting Ollama installation"

    $OllamaVersion = Get-EnvVar -Name "OLLAMA_VERSION" -Default "latest"
    $ModelsToPullRaw = Get-EnvVarOrFail -Name "OLLAMA_MODELS_TO_PULL"

    $GithubBaseUrl = Get-EnvVar `
        -Name "OLLAMA_GITHUB_BASE_URL" `
        -Default "https://github.com/ollama/ollama/releases/download"

    $InstallDir = Get-EnvVar `
        -Name "OLLAMA_INSTALL_DIR" `
        -Default "C:\Program Files\Ollama"

    $ModelStore = Get-EnvVar `
        -Name "OLLAMA_MODEL_STORE" `
        -Default "C:\ProgramData\Ollama\models"

    $TempDir = "C:\Temp\Ollama"

    if ($OllamaVersion -eq "latest") {
        $VersionTag = "latest"
        $DownloadUrl = "https://github.com/ollama/ollama/releases/latest/download/ollama-windows-amd64.zip"
    }
    else {
        $VersionTag = if ($OllamaVersion.StartsWith("v")) { $OllamaVersion } else { "v$OllamaVersion" }
        $DownloadUrl = "$GithubBaseUrl/$VersionTag/ollama-windows-amd64.zip"
    }

    $ZipPath = Join-Path $TempDir "ollama-windows-amd64-$VersionTag.zip"

    $ModelsToPull = ConvertTo-ModelList -RawValue $ModelsToPullRaw

    if (!$ModelsToPull -or $ModelsToPull.Count -eq 0) {
        throw "OLLAMA_MODELS_TO_PULL did not contain any valid model names."
    }

    Write-Log "Ollama version: $VersionTag"
    Write-Log "Download URL: $DownloadUrl"
    Write-Log "Install dir: $InstallDir"
    Write-Log "Model store: $ModelStore"
    Write-Log "Models requested: $($ModelsToPull -join ', ')"

    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    New-Item -ItemType Directory -Path $ModelStore -Force | Out-Null

    Write-Log "Setting system-wide OLLAMA_MODELS=$ModelStore"
    [Environment]::SetEnvironmentVariable("OLLAMA_MODELS", $ModelStore, "Machine")
    $env:OLLAMA_MODELS = $ModelStore

    Write-Log "Downloading Ollama standalone ZIP"

    curl.exe `
        -L `
        --fail `
        --output $ZipPath `
        $DownloadUrl

    if ($LASTEXITCODE -ne 0) {
        throw "Download failed with exit code $LASTEXITCODE"
    }

    Write-Log "Extracting Ollama to $InstallDir"
    Expand-Archive `
        -Path $ZipPath `
        -DestinationPath $InstallDir `
        -Force

    $OllamaExe = Join-Path $InstallDir "ollama.exe"

    if (!(Test-Path $OllamaExe)) {
        throw "ollama.exe not found after extraction at: $OllamaExe"
    }

    Write-Log "Found Ollama executable: $OllamaExe"

    $MachinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($MachinePath -notlike "*$InstallDir*") {
        Write-Log "Adding Ollama install dir to machine PATH"
        [Environment]::SetEnvironmentVariable("Path", "$MachinePath;$InstallDir", "Machine")
        $env:Path = "$env:Path;$InstallDir"
    }

    # New-PublicDesktopShortcut -TargetPath $OllamaExe

    Write-Log "Starting Ollama server"
    $ServerProcess = Start-Process `
        -FilePath $OllamaExe `
        -ArgumentList "serve" `
        -WindowStyle Hidden `
        -PassThru

    Start-Sleep -Seconds 5

    foreach ($Model in $ModelsToPull) {
        Write-Log "Pulling Ollama model: $Model"

        cmd.exe /c "`"$OllamaExe`" pull `"$Model`" >> `"$LogFile`" 2>&1"
        $PullExitCode = $LASTEXITCODE

        if ($PullExitCode -ne 0) {
            throw "Failed to pull Ollama model '$Model'. Exit code: $PullExitCode"
        }

        Write-Log "Successfully pulled model: $Model"
    }

    Write-Log "Listing installed Ollama models"
    & $OllamaExe list 2>&1 | Tee-Object -FilePath $LogFile -Append

    Write-Log "Done. Users may need to sign out/in before PATH and OLLAMA_MODELS are visible in their session."
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    throw
}
