function Install-Solr9 {
    param(
        [Parameter(Mandatory=$true)][string]$InstallDir,
        [Parameter(Mandatory=$true)][string]$TempDir,
        [Parameter(Mandatory=$true)][string]$SolrVersion,
        [string]$SolrInstallDir
    )

    if ([string]::IsNullOrWhiteSpace($SolrInstallDir)) {
        $SolrInstallDir = Join-Path $InstallDir "solr9"
    }

    $SolrArchiveName = "solr-$SolrVersion-src.tgz"
    $SolrArchiveUrl = "https://dlcdn.apache.org/solr/solr/$SolrVersion/$SolrArchiveName"
    $SolrZipPath = Join-Path $TempDir $SolrArchiveName
    $SolrExtractedDir = Join-Path $InstallDir "solr-$SolrVersion"

    Write-Log "---- Starting Apache Solr installation"
    Write-Log "Install Apache Solr (version: $SolrVersion)"
    Write-Log "Download URL: $SolrArchiveUrl"
    Write-Log "Solr install dir: $SolrInstallDir"

    Invoke-WebRequest -Uri $SolrArchiveUrl -OutFile $SolrZipPath
    if (!(Test-Path $SolrZipPath)) {
        throw "Solr archive download failed: $SolrZipPath"
    }

    if (Test-Path $SolrExtractedDir) {
        Remove-Item -Path $SolrExtractedDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    tar -xzf $SolrZipPath -C $InstallDir
    if (!(Test-Path $SolrExtractedDir)) {
        throw "Extracted Solr directory not found: $SolrExtractedDir"
    }

    if (Test-Path $SolrInstallDir) {
        Remove-Item -Path $SolrInstallDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Move-Item -Path $SolrExtractedDir -Destination $SolrInstallDir
    Write-Log "Solr $SolrVersion installed to $SolrInstallDir"
    return $SolrInstallDir
}
