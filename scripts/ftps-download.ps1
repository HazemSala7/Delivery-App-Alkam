# Recursive FTPS (explicit) downloader using .NET FtpWebRequest
param(
    [string]$Server   = "ftp.hrsps.com",
    [string]$User     = "sala7@hrsps.com",
    [string]$Remote   = "/login",
    [string]$Local    = "d:\Apps\Delivery-App-Alkam\backend\login"
)

# Accept self-signed / non-strict certs
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

$sec = Read-Host "FTP password for $User" -AsSecureString
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
$pwd  = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) | Out-Null
$cred = New-Object System.Net.NetworkCredential($User, $pwd)

function New-FtpRequest($uri, $method) {
    $req = [System.Net.FtpWebRequest]::Create($uri)
    $req.Credentials = $cred
    $req.EnableSsl   = $true
    $req.UsePassive  = $true
    $req.UseBinary   = $true
    $req.KeepAlive   = $false
    $req.Method      = $method
    return $req
}

function Get-FtpListing($remoteDir) {
    $uri = "ftp://$Server" + $remoteDir
    if (-not $uri.EndsWith("/")) { $uri += "/" }
    $req = New-FtpRequest $uri ([System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails)
    $resp = $req.GetResponse()
    $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
    $lines = $sr.ReadToEnd() -split "`r?`n" | Where-Object { $_ -ne "" }
    $sr.Close(); $resp.Close()
    $items = @()
    foreach ($line in $lines) {
        # Unix-style: drwxr-xr-x  2 user grp  4096 Jan 01 10:00 name
        if ($line -match '^([dl-])\S+\s+\d+\s+\S+\s+\S+\s+\d+\s+\S+\s+\S+\s+\S+\s+(.+)$') {
            $type = $matches[1]
            $name = $matches[2].Trim()
            if ($name -in @(".","..")) { continue }
            $items += [pscustomobject]@{ Name=$name; IsDir=($type -eq 'd'); IsLink=($type -eq 'l') }
        }
    }
    return $items
}

function Download-FtpFile($remotePath, $localPath) {
    $uri = "ftp://$Server" + $remotePath
    $req = New-FtpRequest $uri ([System.Net.WebRequestMethods+Ftp]::DownloadFile)
    $resp = $req.GetResponse()
    $rs = $resp.GetResponseStream()
    $fs = [System.IO.File]::Create($localPath)
    $rs.CopyTo($fs)
    $fs.Close(); $rs.Close(); $resp.Close()
}

$script:fileCount = 0
$script:skipDirs = @('.git', 'node_modules', 'vendor')
function Sync-Dir($remoteDir, $localDir) {
    if (-not (Test-Path $localDir)) { New-Item -ItemType Directory -Path $localDir | Out-Null }
    Write-Host "DIR  $remoteDir" -ForegroundColor Cyan
    $items = Get-FtpListing $remoteDir
    foreach ($it in $items) {
        if ($it.IsLink) { continue }
        if ($it.IsDir -and ($script:skipDirs -contains $it.Name)) {
            Write-Host "  - skip $remoteDir/$($it.Name)" -ForegroundColor DarkYellow
            continue
        }
        $rp = ($remoteDir.TrimEnd('/')) + "/" + $it.Name
        $lp = Join-Path $localDir $it.Name
        if ($it.IsDir) {
            Sync-Dir $rp $lp
        } else {
            if (Test-Path $lp) {
                # already downloaded - skip to support resume
                $script:fileCount++
                continue
            }
            try {
                Download-FtpFile $rp $lp
                $script:fileCount++
                Write-Host "  + $rp" -ForegroundColor Green
            } catch {
                Write-Host "  ! FAILED $rp : $_" -ForegroundColor Red
            }
        }
    }
}

if (-not (Test-Path $Local)) { New-Item -ItemType Directory -Path $Local -Force | Out-Null }
Sync-Dir $Remote $Local
Write-Host "`nDone. Downloaded $script:fileCount files to $Local" -ForegroundColor Yellow
