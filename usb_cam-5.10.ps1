<#
    .LINK
    https://github.com/Tiger3018/wsl2-kernel-patch-config
#>

# System Info
$Version = @{
    "ps" = $Host.Version;
    "windows" = Get-CimInstance -Class "Win32_OperatingSystem" | Select Version, Buildnumber
}
$SoftwareInstalled = @(
    Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"; 
    Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*";
    Get-StartApps
)
# https://xkln.net/blog/please-stop-using-win32product-to-find-installed-software-alternatives-inside/
# https://www.ipswitch.com/blog/get-ciminstance-vs-get-wmiobject-whats-the-difference
# Get-CimInstance -Query "SELECT * FROM Win32_Product WHERE Name Like 'usbipd-win'"

# Script Info
$SoftwareList = @{
    "usbipd-win" = @{"command" = "usbipd"; "winget" = "usbipd-win"; "default" = "winget"; "fallback-url" = ""};
    "vcxsrv" = @{"winget" = $true; "default" = "url"; "fallback-url" = ""}
}
$MSStoreApiHost = "store.rg-adguard.net"
$GithubCdnHost = "cdn.jsdelivr.net"
$GithubAssetsCdnHost = "download.fastgit.org"
$RepoName = "wsl2-kernel-patch-config"
$ReleaseName = "5.10.102.1-patch"

function Download-Install-AppxPackage {
[CmdletBinding()]
    param (
        [string]$PackageFamilyName,
        [string]$Path
    )

    process {
        # https://serverfault.com/questions/1018220/how-do-i-install-an-app-from-windows-store-using-powershell
        Try {
            # -UseBasicParsing to avoid cookie popup
            $WebResponse = Invoke-WebRequest -UseBasicParsing -Method 'POST' -Uri "https://$MSStoreApiHost/api/GetFiles" -Body "type=PackageFamilyName&url=$PackageFamilyName&ring=Retail" -ContentType 'application/x-www-form-urlencoded'
            $LinksMatch = $WebResponse.Links | where {$_ -like '*_x64*.appx*'} | Select-String -Pattern '(?<=a href=").+(?=" r)'
            $LinksMatch += $WebResponse.Links | where {$_ -like '*2022.927*.msixbundle*'} | Select-String -Pattern '(?<=a href=").+(?=" r)'
            $DownloadLinks = $LinksMatch.matches.value

            for ($i = 1; $i -le $DownloadLinks.Count; $i++) {
                # To escape &amp;
                $DownloadLinkThis = $DownloadLinks[$i-1]
                Invoke-WebRequest -Uri "$DownloadLinkThis" -OutFile "$Path\$PackageFamilyName($i).appx"
                Add-AppxPackage "$Path\$PackageFamilyName($i).appx"
                Remove-Item "$Path\$PackageFamilyName($i).appx"
            }
        }
        Catch {
            Write-Warning ($error[0] | out-string)
            Write-Error "[x] Error occurred. You may manually install WinGet from Microsoft Store (App Installer) or <https://aka.ms/winget>."
            Exit 1
        }
    }
}
function Check-Install-WinGet {
    Try {
        $_ = Get-Command WinGet -ErrorAction Stop
        Write-Host "[*] WinGet is found."
    }
    Catch {
        Write-Host "[*] WinGet is not found. I will download WinGet (App Installer) first."
        Download-Install-AppxPackage "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe" "."
    }
}
function Install-ByWinGet {
    param (
        [string]$Name
    )
    Try {
        $_ = Get-Command $SoftwareList[$Name]["command"] -ErrorAction Stop
        Write-Host "[*] $Name is found."
    }
    Catch {
        Write-Host "[*] $Name is not found. I will install it by WinGet."
        WinGet Install $SoftwareList[$Name]["winget"] #TODO
    }
}

Write-Host "[+] Host"$Version.ps", Windows Build"$Version.windows.version
Write-Host "[+] I will probably use $MSStoreApiHost, $GithubCdnHost and $GithubAssetsCdnHost for better connection in specific location."
Check-Install-WinGet
Install-ByWinGet "usbipd-win"

Write-Host "[+] Downloading pre-built kernel to your home directory."
$HomeDirectory = "$env:homedrive$env:homepath"
Set-Location $HomeDirectory
Invoke-WebRequest -Uri "https://$GithubAssetsCdnHost/tiger3018/$RepoName/releases/download/$ReleaseName/bzImage" -Outfile "bzImage"
Write-Host "[+] Overwriting .wslconfig in your home directory."
Try {
    Move-Item .wslconfig .wslconfig.bak  -ErrorAction Stop
    Write-Host "[*] Creating backup file." # TODO .bak file will prevent upper command.
}
Catch {
}
$HomeDirectory = $HomeDirectory.Replace("\", "\\")
"[wsl2]`r`nkernel=$HomeDirectory\\bzImage" | Out-File .wslconfig -Encoding ascii # Prevent BOM in default Powershell Windows
