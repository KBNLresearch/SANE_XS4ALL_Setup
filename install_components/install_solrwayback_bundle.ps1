function Install-SolrWayback {
    param(
        [Parameter(Mandatory=$true)][string]$InstallDir,
        [Parameter(Mandatory=$true)][string]$TempDir,
        [Parameter(Mandatory=$true)][string]$SolrwaybackVersion,
        [Parameter(Mandatory=$true)][string]$GithubBaseUrl,
        [Parameter(Mandatory=$true)][string]$UserHome
    )

    $VersionToken = if ($SolrwaybackVersion.StartsWith("v")) { $SolrwaybackVersion.Substring(1) } else { $SolrwaybackVersion }
    $VersionedPackageName = "solrwayback_package_$VersionToken"
    $AssetName = "$VersionedPackageName.zip"
    $DownloadUrl = "$GithubBaseUrl/$VersionToken/$AssetName"

    $SolrWaybackInstallDir = Join-Path $InstallDir "solrwayback"
    $ZipPath = Join-Path $TempDir $AssetName

    Write-Log "---- Starting SolrWayback installation"
    Write-Log "Install SolrWayback (version: $SolrwaybackVersion)"
    Write-Log "Download URL: $DownloadUrl"
    Write-Log "SolrWayback install dir: $SolrWaybackInstallDir"
    Write-Log "User home: $UserHome"

    Initialize-Directory $SolrWaybackInstallDir
    Initialize-Directory $UserHome

    Write-Log "Downloading SolrWayback bundle"
    curl.exe -L --fail --output $ZipPath $DownloadUrl
    if ($LASTEXITCODE -ne 0) {
        throw "SolrWayback download failed with exit code $LASTEXITCODE"
    }

    Write-Log "Extracting SolrWayback bundle to $SolrWaybackInstallDir"
    Expand-Archive -Path $ZipPath -DestinationPath $SolrWaybackInstallDir -Force

    $PackageLocation = Join-Path $SolrWaybackInstallDir $VersionedPackageName
    $PropertiesPath = Join-Path $PackageLocation "properties"
    $FilesToCopy = @(
    "solrwayback.properties",
    "solrwaybackweb.properties"
    )

    foreach ($fileName in $FilesToCopy) {
        $sourceFile = Join-Path $PropertiesPath $fileName
        if (!(Test-Path $sourceFile)) {
            throw "Required properties file not found: $sourceFile"
        }

        Copy-Item -Path $sourceFile -Destination $UserHome -Force
        Write-Log "Copied $fileName to $UserHome"
    }

    Write-Log "SolrWayback $SolrwaybackVersion installed to $SolrWaybackInstallDir"
    return $SolrWaybackInstallDir
}
