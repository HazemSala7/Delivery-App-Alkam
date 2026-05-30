param(
    [string]$Server = "ftp.hrsps.com",
    [string]$User   = "hazem@hrsps.com",
    [string]$Path   = "/"
)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

$sec = Read-Host "FTP password for $User" -AsSecureString
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
$pwd  = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) | Out-Null
$cred = New-Object System.Net.NetworkCredential($User, $pwd)

function List($p) {
    $uri = "ftp://$Server" + $p
    if (-not $uri.EndsWith("/")) { $uri += "/" }
    Write-Host "=== LIST $uri ===" -ForegroundColor Cyan
    try {
        $req = [System.Net.FtpWebRequest]::Create($uri)
        $req.Credentials = $cred
        $req.EnableSsl = $true
        $req.UsePassive = $true
        $req.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails
        $resp = $req.GetResponse()
        $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
        Write-Host ($sr.ReadToEnd())
        $sr.Close(); $resp.Close()
    } catch {
        Write-Host "ERR $p : $_" -ForegroundColor Red
    }
}

List "/"
List "/public_html"
List "public_html"
List "/login"
List "login"
