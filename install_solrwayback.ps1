# The script downloads the SolrWayback bundle, extracts it, and copies the
# required properties files into the configured user home folder.
# Also installs Java 11 if not already installed.

# Must be run as Administrator

# Default installation settings
$Default_SolrWaybackVersion = "5.4.2"
$Default_GithubBaseUrl = "https://github.com/netarchivesuite/solrwayback/releases/download"
$Default_InstallDir = "C:\\Program Files\\"
$Default_UserHome = Join-Path $Default_InstallDir "user\\home"
$Default_TomcatVersion = "9.0.119"
$Default_SolrVersion = "9.10.1"

$ErrorActionPreference = "Stop"
$LogFile = "C:\\logs\\install-solrwayback-with-requirements.log"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ComponentDir = Join-Path $ScriptDir "install_components"

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
        throw "Please run this script as an Administrator."
    }
}

function Get-EnvVar {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Default = $null
    )

    $value = [Environment]::GetEnvironmentVariable($Name, "Process")

    if ([string]::IsNullOrWhiteSpace($value)) {
        $value = [Environment]::GetEnvironmentVariable($Name, "User")
    }

    if ([string]::IsNullOrWhiteSpace($value)) {
        $value = [Environment]::GetEnvironmentVariable($Name, "Machine")
    }

    if ([string]::IsNullOrWhiteSpace($value)) {
        return $Default
    }

    return $value
}

function Initialize-Directory {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (!(Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Load-InstallComponents {
    param([Parameter(Mandatory=$true)][string]$ComponentDirectory)

    $scriptFiles = @(
        "install_java11.ps1",
        "install_solrwayback_bundle.ps1",
        "install_tomcat9.ps1",
        "install_solr9.ps1",
        "install_chrome.ps1"
    )

    foreach ($scriptFile in $scriptFiles) {
        $scriptPath = Join-Path $ComponentDirectory $scriptFile
        if (!(Test-Path $scriptPath)) {
            throw "Missing component script: $scriptPath"
        }

        . $scriptPath
    }
}

try {
    Assert-Admin

    Write-Log "Checking whether tar is available (needed for solr installation)"
    Get-Command tar | Out-Null
    Write-Log "tar is available"

    $InstallDir = Get-EnvVar -Name "INSTALL_DIR" -Default $Default_InstallDir
    $TempDir = Join-Path $InstallDir "Temp"
    Initialize-Directory $TempDir

    Load-InstallComponents -ComponentDirectory $ComponentDir

    $JavaHome = Get-EnvVar -Name "JAVA_HOME" -Default (Join-Path $InstallDir "Java\\jdk-11")
    Install-Java11 -InstallDir $InstallDir -TempDir $TempDir -JavaHome $JavaHome

    $SolrwaybackVersion = Get-EnvVar -Name "SOLRWAYBACK_VERSION" -Default $Default_SolrWaybackVersion
    $GithubBaseUrl = Get-EnvVar -Name "SOLRWAYBACK_GITHUB_BASE_URL" -Default $Default_GithubBaseUrl
    $UserHome = Get-EnvVar -Name "SOLRWAYBACK_USER_HOME" -Default $Default_UserHome
    Install-SolrWayback -InstallDir $InstallDir -TempDir $TempDir -SolrwaybackVersion $SolrwaybackVersion -GithubBaseUrl $GithubBaseUrl -UserHome $UserHome

    $TomcatVersion = Get-EnvVar -Name "TOMCAT_VERSION" -Default $Default_TomcatVersion
    $TomcatInstallDir = Get-EnvVar -Name "TOMCAT_INSTALL_DIR" -Default (Join-Path $InstallDir "tomcat9")
    Install-Tomcat9 -InstallDir $InstallDir -TempDir $TempDir -TomcatVersion $TomcatVersion -TomcatInstallDir $TomcatInstallDir

    $SolrVersion = Get-EnvVar -Name "SOLR_VERSION" -Default $Default_SolrVersion
    $SolrInstallDir = Get-EnvVar -Name "SOLR_INSTALL_DIR" -Default (Join-Path $InstallDir "solr9")
    Install-Solr9 -InstallDir $InstallDir -TempDir $TempDir -SolrVersion $SolrVersion -SolrInstallDir $SolrInstallDir

    Install-Chrome -TempDir $TempDir

    Write-Log "SolrWayback and requirements installation complete"
    Write-Log "If screenshot previews are required, verify chrome.command and screenshot.temp.imagedir in $UserHome\\solrwayback.properties"
    Write-Log "Users may need to sign out/in before proceeding."

    if (Test-Path $TempDir) {
        Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "Removed temporary download directory $TempDir"
    }
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    throw
}
