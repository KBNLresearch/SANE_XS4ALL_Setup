function Install-Chrome {
    param(
        [Parameter(Mandatory=$true)][string]$TempDir
    )

    $ChromeInstallerPath = Join-Path $TempDir "googlechromestandaloneenterprise64.msi"
    $ChromeInstallerUrl = "https://dl.google.com/chrome/install/googlechromestandaloneenterprise64.msi"

    Write-Log "---- Starting Google Chrome installation"
    Write-Log "Downloading Google Chrome from $ChromeInstallerUrl"

    Invoke-WebRequest -Uri $ChromeInstallerUrl -OutFile $ChromeInstallerPath
    if (!(Test-Path $ChromeInstallerPath)) {
        throw "Chrome installer download failed: $ChromeInstallerPath"
    }

    Write-Log "Installing Google Chrome"
    Start-Process -FilePath 'msiexec.exe' -Wait -ArgumentList "/i", "`"$ChromeInstallerPath`"", "/qn", "/norestart"
    Write-Log "Google Chrome installed"
}
