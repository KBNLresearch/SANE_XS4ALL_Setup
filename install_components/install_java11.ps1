function Install-Java11 {
    param(
        [Parameter(Mandatory=$true)][string]$InstallDir,
        [Parameter(Mandatory=$true)][string]$TempDir,
        [string]$JavaHome
    )

    if ([string]::IsNullOrWhiteSpace($JavaHome)) {
        $JavaHome = Join-Path $InstallDir "Java\jdk-11"
    }

    Write-Log "---- Starting Java 11 installation"

    if (!(Test-Path $JavaHome)) {
        $msiPath = Join-Path $TempDir "temurin11.msi"
        $javaInstallerUrl = "https://aka.ms/download-jdk/microsoft-jdk-11-windows-x64.msi"

        Write-Log "Java 11 not detected; downloading Java 11 MSI from $javaInstallerUrl"
        Invoke-WebRequest -Uri $javaInstallerUrl -OutFile $msiPath

        Write-Log "Installing Java 11 to $JavaHome"
        Start-Process -FilePath 'msiexec.exe' -Wait -ArgumentList "/i", "`"$msiPath`"", "INSTALLDIR=`"$JavaHome`"", "/qn"

        if (!(Test-Path $JavaHome)) {
            throw "Java 11 path does not exist after installation: $JavaHome"
        }

        Write-Log "Java 11 installed to $JavaHome"
    }
else {
    Write-Log "Java 11 already present at $JavaHome"
}

return $JavaHome
}
