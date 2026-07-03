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

try {
    Assert-Admin

    Write-Log "Checking whether tar is available (needed for solr installation)"
    Get-Command tar
    Write-Log "tar is available"

    $InstallDir = Get-EnvVar `
        -Name "INSTALL_DIR" `
        -Default $Default_InstallDir

    $TempDir = Join-Path $InstallDir "Temp"
    Initialize-Directory $TempDir

    # Install Java11 if not found
    Write-Log "---- Starting Java 11 installation"

    $JavaHome = Get-EnvVar `
        -Name "JAVA_HOME" `
        -Default (Join-Path $InstallDir "Java\\jdk-11")

    if (!(Test-Path $JavaHome)) {
        $msi = Join-Path $env:TEMP "temurin11.msi"
        $javaInstallerUrl = "https://aka.ms/download-jdk/microsoft-jdk-11-windows-x64.msi"

        Write-Log "Java 11 not detected; downloading Java 11 MSI from $javaInstallerUrl"
        Invoke-WebRequest -Uri $javaInstallerUrl -OutFile $msi

        Write-Log "Installing Java 11 to $JavaHome"
        Start-Process -FilePath 'msiexec.exe' -Wait -ArgumentList "/i", "`"$msi`"", "INSTALLDIR=`"$JavaHome`"", "/qn"

        if (Test-Path $JavaHome) {
            $JavaHome = $JavaHome
            Write-Log "Java 11 installed to $JavaHome"
        } else {
            throw "Java 11 path does not exist after installation: $JavaHome"
        }
    } else {
        Write-Log "Java 11 already present  at $JavaHome"
    }

    # Install SolrWayback
    Write-Log "---- Starting SolrWayback installation"

    $SolrwaybackVersion = Get-EnvVar `
        -Name "SOLRWAYBACK_VERSION" `
        -Default $Default_SolrWaybackVersion
    $GithubBaseUrl = Get-EnvVar `
        -Name "SOLRWAYBACK_GITHUB_BASE_URL" `
        -Default $Default_GithubBaseUrl
    $UserHome = Get-EnvVar `
        -Name "SOLRWAYBACK_USER_HOME" `
        -Default $Default_UserHome

    Write-Log "Install SolrWayback (version: $SolrwaybackVersion)"
    $SolrWaybackInstallDir = Join-Path $InstallDir "solrwayback"
    $VersionToken = if ($SolrwaybackVersion.StartsWith("v")) { $SolrwaybackVersion.Substring(1) } else { $SolrwaybackVersion }
    $VersionedPackageName = "solrwayback_package_$VersionToken"
    $AssetName = "$VersionedPackageName.zip"
    $DownloadUrl = "$GithubBaseUrl/$VersionToken/$AssetName"

    $ZipPath = Join-Path $TempDir $AssetName

    Write-Log "Version: $VersionToken"
    Write-Log "Download URL: $DownloadUrl"
    Write-Log "SolrWayback Install dir: $SolrWaybackInstallDir"
    Write-Log "User home: $UserHome"

    Initialize-Directory $SolrWaybackInstallDir
    Initialize-Directory $UserHome

    Write-Log "Downloading SolrWayback bundle"
    curl.exe `
        -L `
        --fail `
        --output $ZipPath `
        $DownloadUrl

    if ($LASTEXITCODE -ne 0) {
        throw "Download failed with exit code $LASTEXITCODE"
    }

    Write-Log "Extracting SolrWayback bundle to $SolrWaybackInstallDir"
    Expand-Archive `
        -Path $ZipPath `
        -DestinationPath $SolrWaybackInstallDir `
        -Force

    $FilesToCopy = @(
    "solrwayback.properties",
    "solrwaybackweb.properties"
    )

    $PackageLocation = Join-Path $SolrWaybackInstallDir $VersionedPackageName
    $PropertiesPath = Join-Path $PackageLocation "properties"

    foreach ($fileName in $FilesToCopy) {
        $sourceFile = Join-Path $PropertiesPath $fileName
        if (!(Test-Path $sourceFile)) {
            throw "Required properties file not found: $sourceFile"
        }

        Copy-Item -Path $sourceFile -Destination $UserHome -Force
        Write-Log "Copied $fileName to $UserHome"
    }
    Write-Log "SolrWayback $SolrWaybackVersion installed to $SolrWaybackInstallDir"

    # Install Tomcat 9
    Write-Log "---- Starting Apache Tomcat installation"

    $TomcatVersion = Get-EnvVar `
        -Name "TOMCAT_VERSION" `
        -Default $Default_TomcatVersion
    $TomcatInstallDir = Get-EnvVar `
        -Name "TOMCAT_INSTALL_DIR" `
        -Default (Join-Path $InstallDir "tomcat9")
    $TomcatArchiveName = "apache-tomcat-$TomcatVersion.zip"
    $TomcatArchiveUrl = "https://dlcdn.apache.org/tomcat/tomcat-9/v$TomcatVersion/bin/$TomcatArchiveName"
    $TomcatZipPath = Join-Path $TempDir $TomcatArchiveName

    Write-Log "Install Apache Tomcat (version: $TomcatVersion)"
    Invoke-WebRequest -Uri $TomcatArchiveUrl -OutFile $TomcatZipPath

    if (!(Test-Path $TomcatZipPath)) {
        throw "Tomcat archive download failed: $TomcatZipPath"
    }

    Expand-Archive `
        -Path $TomcatZipPath `
        -DestinationPath $TomcatInstallDir `
        -Force

    $TomcatExtractedDir = Join-Path $TomcatInstallDir "apache-tomcat-$TomcatVersion"
    if (Test-Path $TomcatInstallDir) {
        Remove-Item -Path $TomcatInstallDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    if (Test-Path $TomcatExtractedDir) {
        Rename-Item -Path $TomcatExtractedDir -NewName "tomcat9"
    }

    Write-Log "Tomcat 9 installed to $TomcatInstallDir"

    # Install Solr 9
    Write-Log "---- Starting Apache Solr installation"
    $SolrVersion = Get-EnvVar `
        -Name "SOLR_VERSION" `
        -Default $Default_SolrVersion
    $SolrInstallDir = Get-EnvVar `
        -Name "SOLR_INSTALL_DIR" `
        -Default (Join-Path $InstallDir "solr9")
    $SolrArchiveName = "solr-$SolrVersion-src.tgz"
    $SolrArchiveUrl = "https://dlcdn.apache.org/solr/solr/$SolrVersion/$SolrArchiveName"
    $SolrZipPath = Join-Path $TempDir $SolrArchiveName

    Write-Log "Install Apache Solr (version: $SolrVersion)"
    Invoke-WebRequest -Uri $SolrArchiveUrl -OutFile $SolrZipPath

    if (!(Test-Path $SolrZipPath)) {
        throw "Solr archive download failed: $SolrZipPath"
    }

    Write-Log "Extract Solr archive"
    tar -xzf $SolrZipPath -C $InstallDir

    $SolrExtractedDir = Join-Path $InstallDir "solr-$SolrVersion"
    if (Test-Path $SolrInstallDir) {
        Remove-Item -Path $SolrInstallDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    if (Test-Path $SolrExtractedDir) {
        Rename-Item -Path $SolrExtractedDir -NewName "solr9"
    }
    Write-Log "Solr $SolrVersion installed to $SolrInstallDir"

    # Install Google Chrome
    Write-Log "---- Starting Google Chrome installation"
    $ChromeInstallerUrl = "https://dl.google.com/chrome/install/googlechromestandaloneenterprise64.msi"
    $ChromeInstallDir = Join-Path $TempDir "GoogleChrome"

    Write-Log "Downloading Google Chrome from $ChromeInstallerUrl"
    Invoke-WebRequest -Uri $ChromeInstallerUrl -OutFile $ChromeInstallDir

    if (!(Test-Path $ChromeInstallDir)) {
        throw "Chrome installer download failed: $ChromeInstallDir"
    }

    Write-Log "Installing Google Chrome"
    Start-Process -FilePath 'msiexec.exe' -Wait -ArgumentList "/i", "`"$ChromeInstallDir`"", "/qn", "/norestart"

    Write-Log "Google Chrome installed"

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
