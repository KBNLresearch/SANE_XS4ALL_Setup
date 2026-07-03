function Install-Tomcat9 {
    param(
        [Parameter(Mandatory=$true)][string]$InstallDir,
        [Parameter(Mandatory=$true)][string]$TempDir,
        [Parameter(Mandatory=$true)][string]$TomcatVersion,
        [string]$TomcatInstallDir
    )

    if ([string]::IsNullOrWhiteSpace($TomcatInstallDir)) {
        $TomcatInstallDir = Join-Path $InstallDir "tomcat9"
    }

    $TomcatArchiveName = "apache-tomcat-$TomcatVersion.zip"
    $TomcatArchiveUrl = "https://dlcdn.apache.org/tomcat/tomcat-9/v$TomcatVersion/bin/$TomcatArchiveName"
    $TomcatZipPath = Join-Path $TempDir $TomcatArchiveName
    $TempExtractDir = Join-Path $TempDir "tomcat9"

    Write-Log "---- Starting Apache Tomcat installation"
    Write-Log "Install Apache Tomcat (version: $TomcatVersion)"
    Write-Log "Download URL: $TomcatArchiveUrl"
    Write-Log "Tomcat install dir: $TomcatInstallDir"

    Invoke-WebRequest -Uri $TomcatArchiveUrl -OutFile $TomcatZipPath
    if (!(Test-Path $TomcatZipPath)) {
        throw "Tomcat archive download failed: $TomcatZipPath"
    }

    if (Test-Path $TempExtractDir) {
        Remove-Item -Path $TempExtractDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    Expand-Archive -Path $TomcatZipPath -DestinationPath $TempExtractDir -Force

    $TomcatExtractedDir = Join-Path $TempExtractDir "apache-tomcat-$TomcatVersion"
    if (!(Test-Path $TomcatExtractedDir)) {
        throw "Extracted Tomcat directory not found: $TomcatExtractedDir"
    }

    if (Test-Path $TomcatInstallDir) {
        Remove-Item -Path $TomcatInstallDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Move-Item -Path $TomcatExtractedDir -Destination $TomcatInstallDir
    Write-Log "Tomcat 9 installed to $TomcatInstallDir"
    return $TomcatInstallDir
}
